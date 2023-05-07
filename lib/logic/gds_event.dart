part of 'gds_bloc.dart';

@immutable
abstract class GdsEvent {}

class AddEdgeButtonPressGdsEvent extends GdsEvent {
  final double throughputFlow;
  AddEdgeButtonPressGdsEvent(this.throughputFlow);}

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

class GdsDeselectElementEvent extends GdsEvent {}

class GdsCreateElementEvent extends GdsEvent {
  final GdsElementType type;

  GdsCreateElementEvent(this.type);
}

class GdsForceUpdateEvent extends GdsEvent {}

class GdsDeleteWorkspaceButtonPressEvent extends GdsEvent {}
