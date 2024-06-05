part of 'editor_page.dart';

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

class _MyLinePainter extends CustomPainter {
  final Offset p1;
  final Offset p2;

  final Color color;

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

class PipelineWidget extends StatelessWidget {
  final Edge? edge;
  final Node? node;
  final bool isSelect;
  final Widget? child;

  const PipelineWidget.edge(
      {required this.edge,
      super.key,
      required this.isSelect,
      required this.child})
      : node = null;

  const PipelineWidget.node({
    required this.node,
    super.key,
    required this.isSelect,
  })  : edge = null,
        child = null;

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    if (node != null) {
      const double dragPointSize = 10.0;
      return Positioned(
        left: node!.position.dx - dragPointSize / 2,
        top: node!.position.dy - dragPointSize / 2,
        child: DeferPointer(
          child: TransparentPointer(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                stateStore.tapOnElement(node!);
              },
              onPanUpdate: (d) {
                if (isSelect) {
                  stateStore.moveElement(d.delta);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(dragPointSize / 4),
                    color: isSelect
                        ? globals.AdditionalColors.planBorderElement
                            .withOpacity(0.5)
                        : Colors.black26,
                    border: Border.all(
                      width: dragPointSize / 10,
                      color: switch (node!.type) {
                        NodeType.base => Colors.blueAccent,
                        NodeType.sink => Colors.purple,
                        NodeType.source => Colors.deepOrangeAccent,
                      }
                          .withOpacity(isSelect ? 1 : 0.5),
                    )),
                width: dragPointSize,
                height: dragPointSize,
              ),
            ),
          ),
        ),
      );
    } else {
      final edge = this.edge!;
      Offset p1 = stateStore.nodeById(edge.startNodeId).position;
      Offset p2 = stateStore.nodeById(edge.endNodeId).position;
      double containerHeight = 10;
      double containerWidth = (p1 - p2).distance;
      double lineToPointLen = min(containerWidth / 2, containerHeight + 5);
      double angle = _getAngle(p1, p2);
      MaterialColor pipeColor = edge.flow != 0 ? Colors.green : Colors.grey;
      final containerPoints = [
        Offset(p1.dx + ((containerHeight / 2) * sin(angle + (pi / 2))),
            p1.dy + ((containerHeight / 2) * cos(angle + (pi / 2)))),
        Offset(p1.dx + ((containerHeight / 2) * sin(angle - (pi / 2))),
            p1.dy + ((containerHeight / 2) * cos(angle - (pi / 2)))),
        Offset(p2.dx + ((containerHeight / 2) * sin(angle + (pi / 2))),
            p2.dy + ((containerHeight / 2) * cos(angle + (pi / 2)))),
        Offset(p2.dx + ((containerHeight / 2) * sin(angle - (pi / 2))),
            p2.dy + ((containerHeight / 2) * cos(angle - (pi / 2)))),
      ];
      final top = containerPoints.map((offset) => offset.dy).reduce(min);
      final left = containerPoints.map((offset) => offset.dx).reduce(min);
      final width = containerPoints.map((offset) => offset.dx).reduce(max) -
          containerPoints.map((offset) => offset.dx).reduce(min);
      final height = containerPoints.map((offset) => offset.dy).reduce(max) -
          containerPoints.map((offset) => offset.dy).reduce(min);
      return Positioned(
        top: top,
        left: left,
        child: SizedOverflowBox(
          size: Size(width, height),
          child: Transform.rotate(
            angle: angle + (pi / 2),
            child: DeferPointer(
              child: TransparentPointer(
                child: GestureDetector(
                  onTap: () {
                    stateStore.tapOnElement(edge);
                  },
                  onPanUpdate: (details) {
                    stateStore.moveElement(
                        _rotateOffset(details.delta, angle + (pi / 2)));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isSelect
                          ? globals.AdditionalColors.planBorderElement
                          : Colors.grey,
                    ),
                    height: containerHeight,
                    width: containerWidth - lineToPointLen,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Offset _rotateOffset(Offset offset, double angle) {
    double sinAngle = sin(angle);
    double cosAngle = cos(angle);
    double dx = offset.dx * cosAngle - offset.dy * sinAngle;
    double dy = offset.dx * sinAngle + offset.dy * cosAngle;
    return Offset(dx, dy);
  }
}

class PipelineSegmentWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelineSegmentWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
      edge: edge,
      isSelect: isSelect,
      child: null,
    );
  }
}

class PipelineNodeWidget extends StatelessWidget {
  final Node node;
  final bool isSelect;

  const PipelineNodeWidget(
      {super.key, required this.node, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class PipelineValveWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;
  const PipelineValveWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
      edge: edge,
      isSelect: isSelect,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child:
              SizedBox(width: 30, child: Image.asset("assets/valve_image.png")),
        ),
      ),
    );
  }
}

class PipelinePercentageValveWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelinePercentageValveWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30,
                child: Image.asset("assets/percentage_valve_image.png")),
          ),
        ));
  }
}

class PipelineFilterWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelineFilterWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30, child: Image.asset("assets/filter_image.png")),
          ),
        ));
  }
}

class PipelineHeaterWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelineHeaterWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30, child: Image.asset("assets/heater_image.png")),
          ),
        ));
  }
}

class PipelineReducerWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelineReducerWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30, child: Image.asset("assets/reducer_image.png")),
          ),
        ));
  }
}

class PipelineMeterWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelineMeterWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30, child: Image.asset("assets/meter_image.png")),
          ),
        ));
  }
}

class PipelineAdorizerWidget extends StatelessWidget {
  final Edge edge;
  final bool isSelect;

  const PipelineAdorizerWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget.edge(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30, child: Image.asset("assets/adorizer_image.png")),
          ),
        ));
  }
}

class LineWithGestureDetector extends StatelessWidget {
  final Offset p1;
  final Offset p2;
  final double tolerance;
  final VoidCallback onTap;
  final bool isSelect;
  final void Function(DragUpdateDetails dragUpdateDetails) onPanUpdate;
  const LineWithGestureDetector(
      {super.key,
      required this.p1,
      required this.p2,
      required this.tolerance,
      required this.onTap,
      required this.onPanUpdate,
      required this.isSelect}); // Максимальное расстояние от линии для срабатывания

  bool isPointOnLine(Offset point, Offset p1, Offset p2, double tolerance) {
    double distance = (point.dx - p1.dx) * (p2.dy - p1.dy) -
        (point.dy - p1.dy) * (p2.dx - p1.dx);
    distance =
        distance.abs() / sqrt(pow(p2.dy - p1.dy, 2) + pow(p2.dx - p1.dx, 2));
    return distance <= tolerance;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (details) {
          Offset touchPosition = details.localPosition;
          if (isPointOnLine(touchPosition, p1, p2, tolerance)) {
            onTap();
          }
        },
        onPanUpdate: onPanUpdate,
        child: CustomPaint(
            size: const Size(
                double.infinity, double.infinity), // Adjust the size as needed
            painter: _MyLinePainter(
              p1,
              p2,
              Colors.blue.withOpacity(isSelect ? 0.8 : 0.3),
            )));
  }
}
