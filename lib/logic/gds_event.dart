part of 'gds_bloc.dart';

@immutable
abstract class GdsEvent {}

class AddElementButtonPressGdsEvent extends GdsEvent {
  final double diam;

  AddElementButtonPressGdsEvent(this.diam);
}

class DeleteElementButtonPressGdsEvent extends GdsEvent {
  DeleteElementButtonPressGdsEvent();
}

class ChangeSelectedTypeInPanelEvent extends GdsEvent {
  final GdsElementType type;

  ChangeSelectedTypeInPanelEvent(this.type);
}

class GdsElementMoveEvent extends GdsEvent {
  final int id;
  final Offset p1;
  final Offset p2;

  GdsElementMoveEvent(this.id, this.p1, this.p2);
}

class GdsPointMoveEvent extends GdsEvent {
  final int pointId;
  final Offset delta;

  GdsPointMoveEvent(this.pointId, this.delta);
}

class CalculateFlowButtonPressGdsEvent extends GdsEvent {}

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

class GdsThroughputFLowPercentageElementChangeEvent extends GdsEvent {
  final GraphEdge element;
  final double value;

  GdsThroughputFLowPercentageElementChangeEvent(this.element, this.value);
}

class GdsTargetPressureReducerElementChangeEvent extends GdsEvent {
  final GraphEdge element;
  final double value;

  GdsTargetPressureReducerElementChangeEvent(this.element, this.value);
}

class GdsLenElementChangeEvent extends GdsEvent {
  final GraphEdge element;
  final double value;

  GdsLenElementChangeEvent(this.element, this.value);
}

class GdsSinkTargetFLowElementChangeEvent extends GdsEvent {
  final GraphEdge element;
  final double value;

  GdsSinkTargetFLowElementChangeEvent(this.element, this.value);
}


class GdsSourcePressureElementChangeEvent extends GdsEvent {
  final GraphEdge element;
  final double value;

  GdsSourcePressureElementChangeEvent(this.element, this.value);
}

class GdsDeselectElementEvent extends GdsEvent {}

class GdsCreateElementEvent extends GdsEvent {
  final GdsElementType type;

  GdsCreateElementEvent(this.type);
}

class ExportGdsToFileEvent extends GdsEvent {}
class LoadFromFileEvent extends GdsEvent {}
class LoadFromDBEvent extends GdsEvent{}