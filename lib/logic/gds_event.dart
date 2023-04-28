part of 'gds_bloc.dart';

@immutable
abstract class GdsEvent {}

class FloatingButtonPressGdsEvent extends GdsEvent {}

class GdsElementMoveEvent extends GdsEvent {
  final int id;
  final double newPositionX;
  final double newPositionY;

  GdsElementMoveEvent(this.id, this.newPositionY, this.newPositionX);
}

class GdsElementChangeSizeEvent extends GdsEvent {
  final int id;

  final double newWidth;
  final double newHeight;

  GdsElementChangeSizeEvent(this.id, this.newWidth, this.newHeight);
}

class GdsSelectElementEvent extends GdsEvent {
  final int id;

  GdsSelectElementEvent(
    this.id,
  );
}

class GdsDeselectElementEvent extends GdsEvent {}

class GdsCreateElementEvent extends GdsEvent {
  final GdsElementType type;

  GdsCreateElementEvent(this.type);
}

class GdsForceUpdateEvent extends GdsEvent {}

class GdsDeleteWorkspaceButtonPressEvent extends GdsEvent {}
