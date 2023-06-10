import 'dart:async';
//import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:gas_distribution_station_model/data/entities/point.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/models/gds_element_type.dart';
import 'package:meta/meta.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;

part 'gds_event.dart';

part 'gds_state.dart';

class GdsPageBloc extends Bloc<GdsEvent, GdsState> {
  GraphPipeline? graph;
  GraphEdge? _selectedElement;
  GdsElementType? _selectedType;
  Map<Offset, List<GraphPoint>> magneticGrid = {};

  GraphPoint? _mag(GraphPoint point) {
    double MAGNETIC_RANGE = 7;
    for (GraphPoint otherPoint in graph!.points.values.toList()) {
      if (point != otherPoint &&
          (point.position.dx - otherPoint.position.dx).abs() <=
              MAGNETIC_RANGE &&
          (point.position.dy - otherPoint.position.dy).abs() <=
              MAGNETIC_RANGE) {
        point.position = otherPoint.position;
        graph!.mergePoints(point, otherPoint);
        return otherPoint;
      }
    }
  }

  GdsPageBloc() : super(GdsInitial()) {
    on<AddElementButtonPressGdsEvent>((event, emit) {
      _addNewEdge(event.diam);
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<DeleteElementButtonPressGdsEvent>((event, emit) {
      _deleteElement(_selectedElement!);
      _selectedElement = null;
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<CalculateFlowButtonPressGdsEvent>((event, emit) {
      graph!.distributeFlowAndCalculatePressure();
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsSelectElementEvent>((event, emit) {
      if (_selectedElement == event.element)
        _selectedElement = null;
      else {
        _selectedElement = event.element;
      }
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsDeselectElementEvent>((event, emit) {
      _selectedElement = null;
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsElementMoveEvent>((event, emit) {
      _selectedElement!.p1.position += event
          .p1; //Offset(_selectedElement!.p1.dx+event.p1.dx,_selectedElement!.p1.dy+event.p1.dy);
      _selectedElement!.p2.position += event
          .p2; // Offset(_selectedElement!.p2.dx+event.p2.dx,_selectedElement!.p2.dy+event.p2.dy);
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsPointMoveEvent>((event, emit) {
      if (graph!.points[event.pointId] != null) {
        GraphPoint p = graph!.points[event.pointId]!;
        p.position += event.delta;
        GraphPoint? otherPoint = _mag(p);
        otherPoint != null ? graph!.mergePoints(p, otherPoint) : 0;
        emit(GdsMainState(graph!, _selectedElement, _selectedType!));
      }
    });
    on<ChangeSelectedTypeInPanelEvent>((event, emit) {
      _selectedType = event.type;
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsThroughputFLowPercentageElementChangeEvent>((event, emit) {
      event.element.changeThroughputFlowPercentage(event.value);
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsSourceFLowElementChangeEvent>((event, emit) {
      event.element.sourceFlow =
          event.value; //todo ограничить максимумом потребления
      //emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsLenElementChangeEvent>((event, emit) {
      event.element.len = event.value;
      //emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<GdsTargetPressureReducerElementChangeEvent>((event, emit) {
      event.element.targetPressure = event.value;
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });
    on<SaveGdsEvent>((event, emit) {
      saveGdsToDB();
    });

    on<LoadGdsEvent>((event, emit) async {
      emit(GdsLoadedState());
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path);
      } else {
        // User canceled the picker
      }
      await loadGdsFromDB();
      emit(GdsMainState(graph!, _selectedElement, _selectedType!));
    });

    // graph = GraphPipeline();
    // graph!.addPoint(position: const Offset(100, 0));
    // graph!.addPoint(position: Offset(100, 100));
    // graph!.addPoint(position: Offset(100, 200));
    // //_graph!.addPoint();
    // graph!.addPoint(position: Offset(100, 300));
    //
    // graph!.link(graph!.points[1]!, graph!.points[2]!, 0.1,
    //     GdsElementType.source, 100, 2);
    // graph!.link(
    //     graph!.points[2]!, graph!.points[3]!, 0.1, GdsElementType.segment, 100);
    // graph!.link(
    //     graph!.points[3]!, graph!.points[4]!, 0.1, GdsElementType.sink, 100);
     _selectedType = GdsElementType.segment;
    //emit(GdsInitial());
    add(LoadGdsEvent());
  }

  void _addNewEdge(double diam) {
    var p1 = graph!.addPoint(position: Offset(300, 300));
    var p2 = graph!.addPoint(position: Offset(300, 400));
    graph!.link(p1, p2, diam, _selectedType!, 0);
  }

  Future<void> saveGdsToDB() async {
    var point_dao = globals.database.pointDAO;
    var edge_dao = globals.database.edgeDAO;
    await point_dao.deleteAllPoints();
    await edge_dao.deleteAllEdges();
    for (var point in graph!.points.values.toList()) {
      await point_dao.insertPoint(GraphPoint.toPointDB(point));
    }
    for (var edge in graph!.edges.values.toList()) {
      await edge_dao.insertEdge(edge.toEdgeDB());
    }
  }

  void _deleteElement(GraphEdge graphEdge) {
    graph!.removeEdgeBy2Points(graphEdge.p1, graphEdge.p2);
  }

  Future<void> loadGdsFromDB() async {
    var point_dao = globals.database.pointDAO;
    var edge_dao = globals.database.edgeDAO;
    var points = await point_dao.getAllPoints();
    var edges = await edge_dao.getAllEdges();
    graph = GraphPipeline(points,edges);
    print(points.length);
  }
}
