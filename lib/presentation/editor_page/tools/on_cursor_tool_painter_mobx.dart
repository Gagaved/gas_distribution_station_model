import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../editor_state_mobx.dart';
import 'mouse_region_mobx.dart';

class OnCursorSelectedToolPainter extends StatefulWidget {
  const OnCursorSelectedToolPainter({super.key, required this.child});
  final Widget child;

  @override
  State<OnCursorSelectedToolPainter> createState() =>
      _OnCursorSelectedToolPainterState();
}

class _OnCursorSelectedToolPainterState
    extends State<OnCursorSelectedToolPainter> {
  Offset? position;
  bool visible = false;
  @override
  Widget build(BuildContext context) {
    const double cursorSize = 10;
    return Observer(builder: (context) {
      final selectedTool = EditorState.of(context).selectedTool;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          visible && selectedTool != null && position != null
              ? switch (selectedTool) {
                  ToolType.edge => _EdgeToolIcon(position: position!),
                  ToolType.node => _NodeToolIcon(position: position!),
                }
              : const SizedBox.shrink(),
        ],
      );
    });
  }
}

class EdgeDraftProjector extends StatefulWidget {
  const EdgeDraftProjector({super.key});

  @override
  State<EdgeDraftProjector> createState() => _EdgeDraftProjectorState();
}

class _EdgeDraftProjectorState extends State<EdgeDraftProjector> {
  @override
  Widget build(BuildContext context) {
    const double cursorSize = 10;
    return Positioned(
      child: Observer(builder: (context) {
        final stateStore = EditorState.of(context);
        final mouserRegionState = MouseRegionPositionState.of(context);

        if (mouserRegionState.inVisibleArea &&
            mouserRegionState.position != null &&
            stateStore.lastCreatedNodeForEdgeTool != null &&
            stateStore.selectedTool == ToolType.edge) {
          return _PipelineWidget(
              stateStore.lastCreatedNodeForEdgeTool!.position,
              mouserRegionState.position!);
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
}

class _PipelineWidget extends StatelessWidget {
  final Offset p1;
  final Offset p2;
  const _PipelineWidget(this.p1, this.p2);

  @override
  Widget build(BuildContext context) {
    double dragPointSize = 10.0;
    double additionalSize = 50;
    double width = (p2.dx - p1.dx).abs() + additionalSize;
    double height = (p2.dy - p1.dy).abs() + additionalSize;
    double angle = _getAngle(p1, p2);
    MaterialColor pipeColor = Colors.grey;
    return Positioned(
      top: min(p1.dy, p2.dy) - (dragPointSize),
      left: min(p1.dx, p2.dx) - (dragPointSize),
      child: Stack(children: [
        SizedBox(
          width: width + dragPointSize * 2,
          height: height + dragPointSize * 2,
          //color: isSelect ? Colors.black12 : null,
          child: Stack(
            children: [
              ///
              ///
              /// Пейнтер линии
              CustomPaint(
                painter: _MyLinePainter(
                    Offset(
                      p1.dx - min(p1.dx, p2.dx) + dragPointSize,
                      p1.dy - min(p1.dy, p2.dy) + dragPointSize,
                    ),
                    Offset(p2.dx - min(p1.dx, p2.dx) + dragPointSize,
                        p2.dy - min(p1.dy, p2.dy) + dragPointSize),
                    pipeColor),
              ),

              ///
              ///
              /// Контейнер для детектора
              SizedBox(
                width: width + dragPointSize * 2 - additionalSize,
                height: height + dragPointSize * 2 - additionalSize,
                child: RotatedBox(
                  quarterTurns: width > height ? 1 : 0,
                  child: Transform.rotate(
                    angle: width > height ? angle - pi / 2 : angle, //
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Container(
                          width: 10,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _MyLinePainter extends CustomPainter {
  final Offset p1;

  final Offset p2;

  final MaterialColor color;

  _MyLinePainter(this.p1, this.p2, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    paint.strokeWidth = 5;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

double _getAngle(Offset p1, Offset p2) {
  double x1 = p1.dx - min(p1.dx, p2.dx);
  double y1 = p1.dy - min(p1.dy, p2.dy);
  double x2 = p2.dx - min(p1.dx, p2.dx);
  double y2 = p2.dy - min(p1.dy, p2.dy);
  double result = pi - atan2(x2 - x1, y2 - y1);
  if ((x2 - x1).abs() > (y2 - y1).abs()) {
    //result+=pi/2;
  }
  return result;
}

class _NodeToolIcon extends StatelessWidget {
  const _NodeToolIcon({super.key, required this.position});
  final Offset position;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.black26,
            border: Border.all(
              width: 3,
              color: Colors.blueAccent.withOpacity(0.5),
            )),
        width: 10,
        height: 10,
      ),
    );
  }
}

class _EdgeToolIcon extends StatelessWidget {
  const _EdgeToolIcon({super.key, required this.position});
  final Offset position;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: SizedBox(
        height: 10,
        width: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black26,
                  border: Border.all(
                    width: 2,
                    color: Colors.blueAccent.withOpacity(0.5),
                  )),
              width: 8,
              height: 8,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black26,
                  border: Border.all(
                    width: 2,
                    color: Colors.blueAccent.withOpacity(0.5),
                  )),
              width: 10,
              height: 3,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black26,
                  border: Border.all(
                    width: 2,
                    color: Colors.blueAccent.withOpacity(0.5),
                  )),
              width: 8,
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}
