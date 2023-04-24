part of 'gds_bloc.dart';

abstract class GdsState {
}

class GdsMainState extends GdsState{
  GdsMainState(this.graph);
  GraphPipeline graph;
}
class GdsInitial extends GdsState {
}
