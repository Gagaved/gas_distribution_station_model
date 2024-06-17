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

class PipelineWidget extends StatelessObserverWidget {
  final Edge? edge;
  final Node? node;
  final bool isSelect;

  const PipelineWidget.edge({
    required this.edge,
    super.key,
    required this.isSelect,
  }) : node = null;

  const PipelineWidget.node({
    required this.node,
    super.key,
    required this.isSelect,
  }) : edge = null;

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
                        : Colors.black12,
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
      final Color selectColor = globals.AdditionalColors.planBorderElement;
      Color basePipeColor = globals.AdditionalColors.lightGray;
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

      final Color pipeColor = switch (ToolsState.of(context).heatMapState) {
        null => basePipeColor,
        HeatMapState.temperature => (stateStore.maxFlow != null &&
                edge.flow.isFinite &&
                edge.flow.abs() > 0.1 &&
                edge.temperature.isFinite &&
                stateStore.maxTemperature != null &&
                stateStore.maxTemperature != 0 &&
                stateStore.maxTemperature!.isFinite)
            ? Color.lerp(Colors.blueAccent, Colors.red,
                min(1, max(0, (edge.temperature - 273.15) / 80)))!
            : basePipeColor,
        HeatMapState.pressure => (stateStore.maxFlow != null &&
                edge.flow.isFinite &&
                edge.flow.abs() > 0.1 &&
                edge.pressure.isFinite &&
                stateStore.maxPressure != null &&
                stateStore.maxPressure != 0 &&
                stateStore.maxPressure!.isFinite)
            ? Color.lerp(basePipeColor, Colors.deepOrange,
                min(1, max(0, edge.pressure / stateStore.maxPressure!)))!
            : basePipeColor,
        HeatMapState.flow => (stateStore.maxFlow != null &&
                edge.flow.isFinite &&
                edge.flow.abs() > 0.01 &&
                stateStore.maxFlow!.isFinite)
            ? Color.lerp(basePipeColor, Colors.blueAccent,
                min(1, max(0, edge.flow.abs() / stateStore.maxFlow!)))!
            : basePipeColor,
        // TODO: Handle this case.
        HeatMapState.adorization => (stateStore.maxFlow != null &&
                edge.flow.isFinite &&
                edge.flow.abs() > 0.1 &&
                edge.pressure.isFinite &&
                edge.isAdorize)
            ? Colors.green
            : basePipeColor,
      };

      final Color statusColor = switch (edge.type) {
        EdgeType.segment => basePipeColor,
        EdgeType.valve =>
          edge.percentageValve != 0 ? Colors.green : Colors.redAccent,
        EdgeType.percentageValve =>
          edge.percentageValve != 0 ? Colors.green : Colors.redAccent,
        EdgeType.heater => edge.heaterOn ? Colors.green : Colors.redAccent,
        EdgeType.adorizer => edge.adorizerOn ? Colors.green : Colors.redAccent,
        EdgeType.meter => edge.flow != 0 ? Colors.green : basePipeColor,
        EdgeType.reducer => edge.flow != 0 ? Colors.green : basePipeColor,
        EdgeType.filter => edge.flow != 0 ? Colors.green : basePipeColor,
      };
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
                      color: pipeColor,
                      border: Border.all(
                          width: 2,
                          color: isSelect ? selectColor : Colors.transparent,
                          strokeAlign: BorderSide.strokeAlignOutside),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: Offset(0, 0.5), // changes position of shadow
                        ),
                      ],
                    ),
                    height: containerHeight,
                    width: containerWidth - lineToPointLen,
                    child: OverflowBox(
                      maxWidth: 25,
                      maxHeight: 30,
                      minWidth: 25,
                      minHeight: 25,
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: SizedBox(
                              height: 25,
                              width: 25,
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: PipelineImageWidget(
                                  backgroundColor: statusColor,
                                  edgeType: edge.type,
                                  borderColor: isSelect
                                      ? selectColor
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          if (edge.type.isDirectional)
                            const Positioned(
                              bottom: -5,
                              child: Icon(
                                Icons.keyboard_backspace,
                                size: 7,
                              ),
                            ),
                        ],
                      ),
                    ),
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

class PipelineImageWidget extends StatelessWidget {
  final EdgeType edgeType;
  final Color backgroundColor;
  final Color borderColor;

  const PipelineImageWidget(
      {super.key,
      required this.edgeType,
      required this.backgroundColor,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final String? asset = switch (edgeType) {
      EdgeType.segment => null,
      EdgeType.valve => "assets/valve_image.png",
      EdgeType.percentageValve => "assets/percentage_valve_image.png",
      EdgeType.heater => "assets/heater_image.png",
      EdgeType.adorizer => "assets/adorizer_image.png",
      EdgeType.meter => "assets/meter_image.png",
      EdgeType.reducer => "assets/reducer_image.png",
      EdgeType.filter => "assets/filter_image.png",
    };
    return asset != null
        ? Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
                border: Border.all(
                  width: 1,
                  color: borderColor,
                )),
            width: 25,
            height: 25,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                asset,
                height: 20,
                width: 20,
                fit: BoxFit.fill,
              ),
            ))
        : const SizedBox.shrink();
  }
}
