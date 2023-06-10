part of 'gds_bloc.dart';

abstract class GdsState {
}

class GdsMainState extends GdsState{
  GdsMainState(this.graph,this.selectedEdge, this.selectedType);
  GraphPipeline graph;
  GraphEdge? selectedEdge;
  GdsElementType selectedType;
}
class GdsInitial extends GdsState {
}
class GdsLoadedState extends GdsState{

}
