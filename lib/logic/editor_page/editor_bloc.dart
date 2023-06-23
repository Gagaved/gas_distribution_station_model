import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:gas_distribution_station_model/models/graph_model.dart';
import 'package:gas_distribution_station_model/data/util/FileManager.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:meta/meta.dart';
part 'editor_event.dart';
part 'editor_state.dart';

class EditorPageBloc extends Bloc<EditorEvent, GdsState> {
  GraphPipeline graph = GraphPipeline();
  GraphEdge? _selectedElement;
  PipelineElementType? _selectedType;
  Map<Offset, List<GraphPoint>> magneticGrid = {};
  CalculateStatus calculateStatus = CalculateStatus.complete;

  EditorPageBloc() : super(EditorInitialState()) {
    on<AddElementButtonPressEditorEvent>((event, emit) {
      var newEdge = _addNewEdge(event.diam);
      _selectedElement = newEdge;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<DeleteElementButtonPressEvent>((event, emit) {
      _deleteElement(_selectedElement!);
      _selectedElement = null;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<CalculateFlowButtonPressEvent>((event, emit) async {
      CalculateStatus.process;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, CalculateStatus.process));
      await graph.calculatePipeline();
      calculateStatus = CalculateStatus.complete;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<GdsSelectElementEditorEvent>((event, emit) {
      if (_selectedElement == event.element) {
        _selectedElement = null;
      } else {
        _selectedElement = event.element;
      }
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<GdsDeselectElementEvent>((event, emit) {
      _selectedElement = null;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<GdsElementMoveEditorEvent>((event, emit) {
      _selectedElement!.p1.position += event
          .p1; //Offset(_selectedElement!.p1.dx+event.p1.dx,_selectedElement!.p1.dy+event.p1.dy);
      _selectedElement!.p2.position += event
          .p2; // Offset(_selectedElement!.p2.dx+event.p2.dx,_selectedElement!.p2.dy+event.p2.dy);
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<GdsPointMoveEditorEvent>((event, emit) {
      if (graph.points[event.pointId] != null) {
        GraphPoint p = graph.points[event.pointId]!;
        p.position += event.delta;
        GraphPoint? otherPoint = _magnatePoint(p);
        otherPoint != null ? graph.mergePoints(p, otherPoint) : 0;
        emit(EditorMainState(
            graph, _selectedElement, _selectedType!, calculateStatus));
      }
    });
    on<ChangeSelectedTypeInPanelEditorEvent>((event, emit) {
      _selectedType = event.type;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<GdsThroughputFLowPercentageElementChangeEvent>((event, emit) {
      event.element.changeThroughputFlowPercentage(event.value);
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<GdsHeaterPowerElementChangeEvent>((event, emit) {
      event.element.heaterPower = (event.value);
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });

    on<GdsSinkTargetFLowElementChangeEvent>((event, emit) {
      event.element.targetFlow =
          event.value; //todo ограничить максимумом потребления
      //emit(GdsMainState(graph!, _selectedElement, _selectedType!,calculateStatus));
    });
    on<GdsLenElementChangeEvent>((event, emit) {
      event.element.len = event.value;
      //emit(GdsMainState(graph!, _selectedElement, _selectedType!,calculateStatus));
    });
    on<GdsDiamElementChangeEvent>((event, emit) {
      event.element.diam = event.value;
      //emit(GdsMainState(graph!, _selectedElement, _selectedType!,calculateStatus));
    });
    on<GdsSourcePressureElementChangeEvent>((event, emit) {
      event.element.pressure = event.value * 1000000;
    });
    on<GdsTargetPressureReducerElementChangeEvent>((event, emit) {
      event.element.targetPressure = event.value;
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<ExportGdsToFileEvent>((event, emit) {
      exportGdsToFile();
    });
    on<ClearButtonPressEditorEvent>((event,emit)async {
      emit(EditorLoadingState());
      await clearGds();
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });
    on<LoadFromFileEvent>((event, emit) async {
      emit(EditorLoadingState());
      await loadGdsFromFile();
      emit(EditorMainState(
          graph, _selectedElement, _selectedType!, calculateStatus));
    });


    _selectedType = PipelineElementType.segment;
    emit(EditorMainState(
        graph, _selectedElement, _selectedType!, calculateStatus));
  }

  GraphPoint? _magnatePoint(GraphPoint point) {
    double magneticRange = 7;
    for (GraphPoint otherPoint in graph.points.values.toList()) {
      if (point != otherPoint &&
          (point.position.dx - otherPoint.position.dx).abs() <= magneticRange &&
          (point.position.dy - otherPoint.position.dy).abs() <= magneticRange) {
        point.position = otherPoint.position;
        graph.mergePoints(point, otherPoint);
        return otherPoint;
      }
    }
    return null;
  }

  GraphEdge _addNewEdge(double diam) {
    var p1 = graph.addPoint(position: const Offset(300, 300));
    var p2 = graph.addPoint(position: const Offset(300, 400));
    return graph.link(p1, p2, diam, _selectedType!, 0);
  }

  Future<void> exportGdsToFile() async {
    String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'output-file.Json',
    );
    if (path != null) {
        FileManager.writePointsAndEdgesToFile(graph.points.values.toList(),graph.edges.values.toList(), path);
    } else {
      throw Exception("error load file");
    }
  }

  void _deleteElement(GraphEdge graphEdge) {
    graph.removeEdgeBy2Points(graphEdge.p1, graphEdge.p2);
  }

  Future<void> loadGdsFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      var (points,edges) = FileManager.readPointsAndEdgesFromFile(file);
      graph = GraphPipeline.fromPointsAndEdges(points, edges);
    } else {
      // User canceled the picker
    }
  }

  Future<void> clearGds() async {
    graph = GraphPipeline.fromPointsAndEdges([], []);
    return;
  }
}
