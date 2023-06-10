import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/models/gds_element_type.dart';
import 'package:gas_distribution_station_model/presentation/styles.dart';

double _getAngle(Offset p1, Offset p2) {
  double x1 = p1.dx - min(p1.dx, p2.dx);
  double y1 = p1.dy - min(p1.dy, p2.dy);
  double x2 = p2.dx - min(p1.dx, p2.dx);
  double y2 = p2.dy - min(p1.dy, p2.dy);
  double k = (y2 - y1) / (x2 - x1);
  double result = pi - atan2(x2 - x1, y2 - y1);
  if ((x2 - x1).abs() > (y2 - y1).abs()) {
    //result+=pi/2;
  }
  return result;
}

double _getLen(Offset p1, Offset p2) {
  double width = (p2.dx - p1.dx).abs();
  double height = (p2.dy - p1.dy).abs();
  return sqrt(width * width + height * height);
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
    double len = _getLen(p1, p2);
    MaterialColor pipeColor = edge.openPercentage == 0
        ? Colors.red
        : edge.flow != 0
            ? Colors.green
            : Colors.grey;
    return Positioned(
      top: min(p1.dy, p2.dy) - (dragPointSize),
      left: min(p1.dx, p2.dx) - (dragPointSize),
      child: Stack(children: [
        Positioned(
          right: 0,
          top: additionalSize / 2,
          child: Text(
            "flow:${edge.flow.toStringAsFixed(2)}",
            style: TextStyle(fontSize: isSelect ? 25 : 10),
          ),
        ),
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
                        .read<GdsPageBloc>()
                        .add(GdsSelectElementEvent(edge));
                  },
                  onPanUpdate: (d) {
                    if (isSelect) {
                      context
                          .read<GdsPageBloc>()
                          .add(GdsPointMoveEvent(edge.p1.id, d.delta));
                    }
                  },
                  child: Container(
                    width: dragPointSize,
                    height: dragPointSize,
                    color: isSelect ? AdditionalColors.planBorderElement : null,
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
                        .read<GdsPageBloc>()
                        .add(GdsSelectElementEvent(edge));
                  },
                  onPanUpdate: (d) {
                    if (isSelect) {
                      context
                          .read<GdsPageBloc>()
                          .add(GdsPointMoveEvent(edge.p2.id, d.delta));
                    }
                  },
                  child: Container(
                    width: dragPointSize,
                    height: dragPointSize,
                    color: isSelect ? AdditionalColors.planBorderElement : null,
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
                        .read<GdsPageBloc>()
                        .add(GdsSelectElementEvent(edge));
                  },
                  onPanUpdate: (d) {
                    if (isSelect) {
                      context
                          .read<GdsPageBloc>()
                          .add(GdsElementMoveEvent(id, d.delta, d.delta));
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
                                ? AdditionalColors.debugTranslucent
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
                              .read<GdsPageBloc>()
                              .add(GdsSelectElementEvent(edge));
                        },
                        onPanUpdate: (d) {
                          if (isSelect) {
                            context
                                .read<GdsPageBloc>()
                                .add(GdsElementMoveEvent(id, d.delta, d.delta));
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

class PipelineInformationCardWidget extends StatelessWidget {
  const PipelineInformationCardWidget({Key? key, required this.edge})
      : super(key: key);
  final GraphEdge edge;
  static TextEditingController sourceFlowValueTextController =
      TextEditingController();
  static TextEditingController lenValueTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    sourceFlowValueTextController.text = edge.sourceFlow.toString();
    lenValueTextController.text = edge.len.toString();
    return Card(
      elevation: 10,
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(edge.type.name.toUpperCase()),
            Text("id: ${edge.id}"),
            Text("PtoP: ${edge.p1.id}-${edge.p2.id}"),
            Text("длина участка: ${edge.len}"),
            Text("Flow: ${edge.flow} м^2 / c"),
            Text("Давление: ${edge.pressure / 1000000} МПа"),
            Text("Диаметр: ${edge.diam} м"),
            Container(
              width: 100,
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: lenValueTextController,
                onChanged: (str) {
                  context.read<GdsPageBloc>().add(
                      GdsLenElementChangeEvent(
                          edge,
                          double.parse(
                              lenValueTextController.value.text)));
                },
                decoration: const InputDecoration(
                  labelText: 'Длина',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            (edge.type == GdsElementType.valve)
                ? MaterialButton(
                    color: edge.openPercentage == 0
                        ? Colors.redAccent
                        : Colors.lightGreen,
                    child: Text(
                        edge.openPercentage == 0 ? "Закрыт" : "Открыт"),
                    onPressed: () {
                      context.read<GdsPageBloc>().add(
                          GdsThroughputFLowPercentageElementChangeEvent(
                              edge, edge.openPercentage == 0 ? 1 : 0));
                    },
                  )
                : const SizedBox.shrink(),
            (edge.type == GdsElementType.percentageValve)
                ? Text(
                    "Открыт на ${(edge.openPercentage * 100).toInt()}%")
                : const SizedBox.shrink(),
            (edge.type == GdsElementType.percentageValve)
                ? Slider(
                    value: edge.openPercentage * 100,
                    max: 100,
                    divisions: 10,
                    label: edge.openPercentage.toString(),
                    onChanged: (double value) {
                      context.read<GdsPageBloc>().add(
                          GdsThroughputFLowPercentageElementChangeEvent(
                              edge, value / 100));
                    },
                  )
                : const SizedBox.shrink(),
            (edge.type == GdsElementType.source)
                ? Container(
                    width: 100,
                    padding:
                        EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: sourceFlowValueTextController,
                      onChanged: (str) {
                        context.read<GdsPageBloc>().add(
                            GdsSourceFLowElementChangeEvent(
                                edge,
                                double.parse(sourceFlowValueTextController
                                    .value.text)));
                      },
                      decoration: const InputDecoration(
                        labelText: 'Источник',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            (edge.type == GdsElementType.reducer)
                ? Text(
                    "Давление на которое\n настроен редуктор: ${edge.targetPressure / 1000000} МПа")
                : const SizedBox.shrink(),
            (edge.type == GdsElementType.reducer)
                ? Slider(
                    value: edge.targetPressure / 1000000,
                    max: 2,
                    min: 1,
                    divisions: 10,
                    label: "${edge.targetPressure / 1000000}МПа",
                    onChanged: (double value) {
                      context.read<GdsPageBloc>().add(
                          GdsTargetPressureReducerElementChangeEvent(
                              edge, value * 1000000));
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
