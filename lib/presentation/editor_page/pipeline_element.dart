import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/logic/editor_page/editor_bloc.dart';
import 'package:gas_distribution_station_model/models/graph_model.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;
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

class PipelineWidget extends StatelessWidget {
  final GraphEdge edge;
  final bool isSelect;
  final Widget? child;

  const PipelineWidget(
      {required this.edge,
      super.key,
      required this.isSelect,
      required this.child});

  @override
  Widget build(BuildContext context) {
    int id = edge.id;
    Offset p1 = edge.p1.position;
    Offset p2 = edge.p2.position;
    double dragPointSize = 10.0;
    double additionalSize = 50;
    double width = (p2.dx - p1.dx).abs() + additionalSize;
    double height = (p2.dy - p1.dy).abs() + additionalSize;
    double angle = _getAngle(p1, p2);
    MaterialColor pipeColor = edge.openPercentage == 0
        ? Colors.red
        : edge.flow != 0
            ? Colors.green
            : Colors.grey;
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
              /// первая точке
              Positioned(
                left: p1.dx - min(p1.dx, p2.dx) + dragPointSize / 2,
                top: p1.dy - min(p1.dy, p2.dy) + dragPointSize / 2,
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<EditorPageBloc>()
                        .add(GdsSelectElementEditorEvent(edge));
                  },
                  onPanUpdate: (d) {
                    if (isSelect) {
                      context
                          .read<EditorPageBloc>()
                          .add(GdsPointMoveEditorEvent(edge.p1.id, d.delta));
                    }
                  },
                  child: Container(
                    width: dragPointSize,
                    height: dragPointSize,
                    color: isSelect ? globals.AdditionalColors.planBorderElement : null,
                  ),
                ),
              ),

              ///
              ///
              /// вторая точке
              Positioned(
                left: p2.dx - min(p1.dx, p2.dx) + dragPointSize / 2,
                top: p2.dy - min(p1.dy, p2.dy) + dragPointSize / 2,
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<EditorPageBloc>()
                        .add(GdsSelectElementEditorEvent(edge));
                  },
                  onPanUpdate: (d) {
                    if (isSelect) {
                      context
                          .read<EditorPageBloc>()
                          .add(GdsPointMoveEditorEvent(edge.p2.id, d.delta));
                    }
                  },
                  child: Container(
                    width: dragPointSize,
                    height: dragPointSize,
                    color: isSelect ? globals.AdditionalColors.planBorderElement : null,
                  ),
                ),
              ),

              ///
              ///
              /// Контейнер для детектора
              SizedBox(
                width: width + dragPointSize * 2 - additionalSize,
                height: height + dragPointSize * 2 - additionalSize,
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<EditorPageBloc>()
                        .add(GdsSelectElementEditorEvent(edge));
                  },
                  onPanUpdate: (d) {
                    if (isSelect) {
                      context
                          .read<EditorPageBloc>()
                          .add(GdsElementMoveEditorEvent(id, d.delta, d.delta));
                    }
                  },
                  child: RotatedBox(
                    quarterTurns: width > height ? 1 : 0,
                    child: Transform.rotate(
                      angle: width > height ? angle - pi / 2 : angle, //
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Container(
                            width: 10,
                            color: isSelect
                                ? globals.AdditionalColors.debugTranslucent
                                : Colors.black26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              ///
              ///
              /// Значек
              child != null
                  ? SizedBox(
                      width: width + dragPointSize * 2 - additionalSize,
                      height: height + dragPointSize * 2 - additionalSize,
                      child: GestureDetector(
                        onTap: () {
                          context
                              .read<EditorPageBloc>()
                              .add(GdsSelectElementEditorEvent(edge));
                        },
                        onPanUpdate: (d) {
                          if (isSelect) {
                            context
                                .read<EditorPageBloc>()
                                .add(GdsElementMoveEditorEvent(id, d.delta, d.delta));
                          }
                        },
                        child: RotatedBox(
                          quarterTurns: width > height ? 1 : 0,
                          child: Transform.rotate(
                              angle: width > height ? angle - pi / 2 : angle, //
                              child: child),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        ),
      ]),
    );
  }
}

class PipelineSegmentWidget extends StatelessWidget {
  final GraphEdge edge;
  final bool isSelect;

  const PipelineSegmentWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
      edge: edge,
      isSelect: isSelect,
      child: null,
    );
  }
}

class PipelineValveWidget extends StatelessWidget {
  final GraphEdge edge;
  final bool isSelect;

  const PipelineValveWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
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
  final GraphEdge edge;
  final bool isSelect;

  const PipelinePercentageValveWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
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
  final GraphEdge edge;
  final bool isSelect;

  const PipelineFilterWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
        edge: edge,
        isSelect: isSelect,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
                width: 30,
                child: Image.asset("assets/filter_image.png")),
          ),
        ));
  }
}

class PipelineHeaterWidget extends StatelessWidget {
  final GraphEdge edge;
  final bool isSelect;

  const PipelineHeaterWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
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
  final GraphEdge edge;
  final bool isSelect;

  const PipelineReducerWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
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
  final GraphEdge edge;
  final bool isSelect;

  const PipelineMeterWidget(
      {required this.edge, super.key, required this.isSelect});

  @override
  Widget build(BuildContext context) {
    return PipelineWidget(
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