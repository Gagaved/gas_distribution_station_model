part of 'gds_bloc.dart';
enum CalculateStatus { process, complete, error }

abstract class GdsState {
}

class GdsMainState extends GdsState{
  GdsMainState(this.graph,this.selectedEdge, this.selectedType,this.calculateStatus);
  CalculateStatus calculateStatus;
  GraphPipeline graph;
  GraphEdge? selectedEdge;
  GdsElementType selectedType;
}
class GdsInitial extends GdsState {
}
class GdsLoadingState extends GdsState{

}
