part of 'editor_bloc.dart';

@immutable
abstract class EditorEvent {}

class AddElementButtonPressEditorEvent extends EditorEvent {
  final double diam;

  AddElementButtonPressEditorEvent(this.diam);
}

class DeleteElementButtonPressEvent extends EditorEvent {
  DeleteElementButtonPressEvent();
}

class ChangeSelectedTypeInPanelEditorEvent extends EditorEvent {
  final PipelineElementType type;

  ChangeSelectedTypeInPanelEditorEvent(this.type);
}

class GdsElementMoveEditorEvent extends EditorEvent {
  final int id;
  final Offset p1;
  final Offset p2;

  GdsElementMoveEditorEvent(this.id, this.p1, this.p2);
}

class GdsPointMoveEditorEvent extends EditorEvent {
  final int pointId;
  final Offset delta;

  GdsPointMoveEditorEvent(this.pointId, this.delta);
}

class CalculateFlowButtonPressEvent extends EditorEvent {}
class ClearButtonPressEditorEvent extends EditorEvent{}
class GdsElementChangeSizeEditorEvent extends EditorEvent {
  final int id;
  final double newWidth;
  final double newHeight;

  GdsElementChangeSizeEditorEvent(this.id, this.newWidth, this.newHeight);
}

class GdsSelectElementEditorEvent extends EditorEvent {
  final GraphEdge element;

  GdsSelectElementEditorEvent(
    this.element,
  );
}

class GdsThroughputFLowPercentageElementChangeEvent extends EditorEvent {
  final GraphEdge element;
  final double value;

  GdsThroughputFLowPercentageElementChangeEvent(this.element, this.value);
}

class GdsTargetPressureReducerElementChangeEvent extends EditorEvent {
  final GraphEdge element;
  final double value;

  GdsTargetPressureReducerElementChangeEvent(this.element, this.value);
}

class GdsLenElementChangeEvent extends EditorEvent {
  final GraphEdge element;
  final double value;

  GdsLenElementChangeEvent(this.element, this.value);
}

class GdsSinkTargetFLowElementChangeEvent extends EditorEvent {
  final GraphEdge element;
  final double value;

  GdsSinkTargetFLowElementChangeEvent(this.element, this.value);
}

class GdsHeaterPowerElementChangeEvent extends EditorEvent {
  final GraphEdge element;
  final double value;

  GdsHeaterPowerElementChangeEvent(this.element, this.value);
}

class GdsSourcePressureElementChangeEvent extends EditorEvent {
  final GraphEdge element;
  final double value;

  GdsSourcePressureElementChangeEvent(this.element, this.value);
}

class GdsDeselectElementEvent extends EditorEvent {}
class GdsDiamElementChangeEvent extends EditorEvent{
  final double value;
  final GraphEdge element;

  GdsDiamElementChangeEvent(this.value, this.element);

}

class GdsCreateElementEvent extends EditorEvent {
  final PipelineElementType type;

  GdsCreateElementEvent(this.type);
}

class ExportGdsToFileEvent extends EditorEvent {}

class LoadFromFileEvent extends EditorEvent {}

class LoadFromDBEvent extends EditorEvent {}
