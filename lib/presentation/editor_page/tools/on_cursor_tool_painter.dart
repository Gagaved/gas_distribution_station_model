import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../editor_state_mobx.dart';

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
    return MouseRegion(
      onEnter: (event) {
        print(event);
        visible = true;
      },
      onExit: (event) {
        print(event);
        visible = false;
      },
      onHover: (event) {
        setState(() {
          position = event.localPosition + const Offset(cursorSize, cursorSize);
        });
      },
      child: Observer(builder: (context) {
        final selectedTool = EditorState.of(context).selectedTool;
        return Stack(
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
      }),
    );
  }
}

class EdgeDraftProjector extends StatefulWidget {
  const EdgeDraftProjector({super.key});

  @override
  State<EdgeDraftProjector> createState() => _EdgeDraftProjectorState();
}

class _EdgeDraftProjectorState extends State<EdgeDraftProjector> {
  Offset? position;
  bool visible = false;
  @override
  Widget build(BuildContext context) {
    const double cursorSize = 10;
    return MouseRegion(
      onEnter: (event) {
        print(event);
        visible = true;
      },
      onExit: (event) {
        print(event);
        visible = false;
      },
      onHover: (event) {
        setState(() {
          position = event.localPosition + const Offset(cursorSize, cursorSize);
        });
      },
      child: Observer(builder: (context) {
        final selectedTool = EditorState.of(context).selectedTool;
        return Stack(
          children: [
            visible && selectedTool != null && position != null
                ? switch (selectedTool) {
                    ToolType.edge => _EdgeToolIcon(position: position!),
                    ToolType.node => _NodeToolIcon(position: position!),
                  }
                : const SizedBox.shrink(),
          ],
        );
      }),
    );
  }
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
