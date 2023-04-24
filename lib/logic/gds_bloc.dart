import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:meta/meta.dart';

part 'gds_event.dart';

part 'gds_state.dart';

class GdsBloc extends Bloc<GdsEvent, GdsState> {
  GraphPipeline? _graph;

  GdsBloc() : super(GdsInitial()) {
    on<FloatingButtonPressGdsEvent>((event, emit) {
      _graph!.flowFordFulkersonAlgorithm();
      print('emit!');
      emit(GdsMainState(_graph!));
    });

    _graph = GraphPipeline();
    _graph!.points.add(PipelinePoint(1),);
    _graph!.points.add(PipelinePoint(2),);
    _graph!.points.add(PipelinePoint(3),);
    _graph!.points.add(PipelinePoint(4),);
    _graph!.points.add(PipelinePoint(5),);
    _graph!.points.add(PipelinePoint(6));

    _graph!.sourcePoints.add(_graph!.points[0]);
    _graph!.sinkPoints.add(_graph!.points[5]);

    _graph!.link(100, 0,_graph!.points[0],_graph!.points[1],100);
    _graph!.link(100, 100,_graph!.points[1],_graph!.points[2],1000);
    _graph!.link(50, 200,_graph!.points[1],_graph!.points[3],1000);
    _graph!.link(150, 200,_graph!.points[2],_graph!.points[4],1000);
    _graph!.link(100, 300,_graph!.points[3],_graph!.points[4],1000);
    _graph!.link(100, 400,_graph!.points[4],_graph!.points[5],100);
    emit(GdsMainState(_graph!));
    }
}

