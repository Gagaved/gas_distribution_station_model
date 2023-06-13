part of 'editor_bloc.dart';
enum CalculateStatus { process, complete, error }

abstract class GdsState {
}

class EditorMainState extends GdsState{
  EditorMainState(this.graph,this.selectedEdge, this.selectedType,this.calculateStatus);
  CalculateStatus calculateStatus;
  GraphPipeline graph;
  GraphEdge? selectedEdge;
  PipelineElementType selectedType;
}
class EditorInitialState extends GdsState {
}
class EditorLoadingState extends GdsState{

}
