import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/models/gds_element_type.dart';
import 'package:meta/meta.dart';

part 'gds_event.dart';

part 'gds_state.dart';

class GdsPageBloc extends Bloc<GdsEvent, GdsState> {
  GraphPipeline? _graph;
  GraphEdge? selectedElement;
  GdsPageBloc() : super(GdsInitial()) {
    on<FloatingButtonPressGdsEvent>((event, emit) {
      _graph!.distributeFlow();
      print('emit!');
      emit(GdsMainState(_graph!));
    });

    _graph = GraphPipeline();
    _graph!.addPoint(isSource: true,sourceFlow: 100);
    _graph!.addPoint();
    _graph!.addPoint();
    _graph!.addPoint();
    _graph!.addPoint();
    //_graph!.addPoint();
    _graph!.addPoint(isSink: true);

    _graph!.link(const Offset(100,0), const Offset(100, 100),_graph!.points[0],_graph!.points[1],100);
    _graph!.link(const Offset(100,100), const Offset(25, 200),_graph!.points[1],_graph!.points[2],1000);
    _graph!.link(const Offset(100,100), const Offset(175, 200),_graph!.points[1],_graph!.points[3],1000);
    _graph!.link(const Offset(25, 200), const Offset(100, 300),_graph!.points[2],_graph!.points[4],1000);
    _graph!.link(const Offset(175, 200), const Offset(100, 300),_graph!.points[3],_graph!.points[4],1000);
    _graph!.link(const Offset(100, 300), const Offset(100, 400),_graph!.points[4],_graph!.points[5],100);
    emit(GdsMainState(_graph!));
    }
}

