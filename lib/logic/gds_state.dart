part of 'gds_bloc.dart';

abstract class GdsState {
}

class GdsMainState extends GdsState{
  GdsMainState(this.graph,this.selectedEdge);
  GraphPipeline graph;
  GraphEdge? selectedEdge;
}
class GdsInitial extends GdsState {
}
