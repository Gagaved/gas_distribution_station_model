part of 'gds_bloc.dart';

@immutable
abstract class GdsEvent {}

class AddElementButtonPressGdsEvent extends GdsEvent {
  final double throughputFlow;
  AddElementButtonPressGdsEvent(this.throughputFlow);}

class DeleteElementButtonPressGdsEvent extends GdsEvent {
  DeleteElementButtonPressGdsEvent();}

class ChangeSelectedTypeInPanelEvent extends GdsEvent{
  final GdsElementType type;

  ChangeSelectedTypeInPanelEvent(this.type);
}

class GdsElementMoveEvent extends GdsEvent {
  final int id;
  final Offset p1;
  final Offset p2;

  GdsElementMoveEvent(this.id, this.p1,this.p2);
}

class GdsPointMoveEvent extends GdsEvent {
  final int pointId;
  final Offset delta;

  GdsPointMoveEvent(this.pointId, this.delta);
}
class CalculateFlowButtonPressGdsEvent extends GdsEvent{

}


class GdsElementChangeSizeEvent extends GdsEvent {
  final int id;

  final double newWidth;
  final double newHeight;

  GdsElementChangeSizeEvent(this.id, this.newWidth, this.newHeight);
}

class GdsSelectElementEvent extends GdsEvent {
  final GraphEdge element;

  GdsSelectElementEvent(
    this.element,
  );
}
class GdsThroughputFLowPercentageElementChangeEvent extends GdsEvent{
  final GraphEdge element;
  final double value;
  GdsThroughputFLowPercentageElementChangeEvent(this.element,this.value);

}

    class GdsSourceFLowElementChangeEvent extends GdsEvent{
  final GraphEdge element;
  final double value;
  GdsSourceFLowElementChangeEvent(this.element,this.value);

}

class GdsDeselectElementEvent extends GdsEvent {}

class GdsCreateElementEvent extends GdsEvent {
  final GdsElementType type;

  GdsCreateElementEvent(this.type);
}

class GdsForceUpdateEvent extends GdsEvent {}