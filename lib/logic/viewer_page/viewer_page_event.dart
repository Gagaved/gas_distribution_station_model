part of 'viewer_page_bloc.dart';

@immutable
abstract class ViewerPageEvent {}


class CalculateFlowButtonPressViewerEvent extends ViewerPageEvent {}


class SelectElementViewerEvent extends ViewerPageEvent {
  final GraphEdge element;

  SelectElementViewerEvent(
      this.element,
      );
}

class ThroughputFLowPercentageElementChangeViewerEvent extends ViewerPageEvent {
  final GraphEdge element;
  final double value;

  ThroughputFLowPercentageElementChangeViewerEvent(this.element, this.value);
}

class TargetPressureReducerElementChangeViewerEvent extends ViewerPageEvent {
  final GraphEdge element;
  final double value;

  TargetPressureReducerElementChangeViewerEvent(this.element, this.value);
}

class SinkTargetFLowElementChangeViewerEvent extends ViewerPageEvent {
  final GraphEdge element;
  final double value;

  SinkTargetFLowElementChangeViewerEvent(this.element, this.value);
}

class GdsHeaterPowerElementChangeViewerEvent extends ViewerPageEvent {
  final GraphEdge element;
  final double value;

  GdsHeaterPowerElementChangeViewerEvent(this.element, this.value);
}

class SourcePressureElementChangeViewerEvent extends ViewerPageEvent {
  final GraphEdge element;
  final double value;

  SourcePressureElementChangeViewerEvent(this.element, this.value);
}

class DeselectElementViewerEvent extends ViewerPageEvent {}