// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:gas_distribution_station_model/models/graph_model.dart';
// import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
// part 'viewer_page_event.dart';
//
// part 'viewer_page_state.dart';
//
// class ViewerPageBloc extends Bloc<ViewerPageEvent, ViewerPageState> {
//   GraphPipeline graph = GraphPipeline();
//   GraphEdge? _selectedElement;
//   final PipelineElementType _selectedType = PipelineElementType.segment;
//   Map<Offset, List<GraphPoint>> magneticGrid = {};
//   CalculateStatus calculateStatus = CalculateStatus.complete;
//
//   ViewerPageBloc() : super(ViewerPageInitial()) {
//     on<CalculateFlowButtonPressViewerEvent>((event, emit) async {
//       CalculateStatus.process;
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, CalculateStatus.process));
//       await graph.calculatePipeline();
//       calculateStatus = CalculateStatus.complete;
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, calculateStatus));
//     });
//     on<SelectElementViewerEvent>((event, emit) {
//       if (_selectedElement == event.element) {
//         _selectedElement = null;
//       } else {
//         _selectedElement = event.element;
//       }
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, calculateStatus));
//     });
//     on<DeselectElementViewerEvent>((event, emit) {
//       _selectedElement = null;
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, calculateStatus));
//     });
//     on<ThroughputFLowPercentageElementChangeViewerEvent>((event, emit) {
//       event.element.changeThroughputFlowPercentage(event.value);
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, calculateStatus));
//     });
//     on<GdsHeaterPowerElementChangeViewerEvent>((event, emit) {
//       event.element.heaterPower = (event.value);
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, calculateStatus));
//     });
//     on<SinkTargetFLowElementChangeViewerEvent>((event, emit) {
//       event.element.targetFlow =
//           event.value; //todo ограничить максимумом потребления
//       //emit(GdsMainState(graph!, _selectedElement, _selectedType!,calculateStatus));
//     });
//     on<SourcePressureElementChangeViewerEvent>((event, emit) {
//       event.element.pressure = event.value * 1000000;
//     });
//     on<TargetPressureReducerElementChangeViewerEvent>((event, emit) {
//       event.element.targetPressure = event.value;
//       emit(ViewerMainState(
//           graph, _selectedElement, _selectedType, calculateStatus));
//     });
//     emit(ViewerMainState(
//         graph, _selectedElement, _selectedType, calculateStatus));
//   }
// }
