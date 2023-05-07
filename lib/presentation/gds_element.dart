import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
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

class PipelineSegmentWidget extends StatelessWidget {
  final GraphEdge edge;
  final bool isSelect;

  PipelineSegmentWidget(
      {required this.edge, super.key, required this.isSelect});

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

    return Positioned(
      top: min(p1.dy, p2.dy) - (dragPointSize),
      left: min(p1.dx, p2.dx) - (dragPointSize),
      child: Stack(children: [
        Positioned(
          child: Text(
            "flow:${edge.flow.toStringAsFixed(2)}",
            style: TextStyle(fontSize: isSelect ? 25 : 10),
          ),
          right: 0,
          top: additionalSize / 2,
        ),
        Container(
          width: width + dragPointSize * 2,
          height: height + dragPointSize * 2,
          color: isSelect ? Colors.black12 : null,
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
              )),

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
                    color: isSelect?AdditionalColors.planBorderElementTranslucent:null,
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
                    color: isSelect?AdditionalColors.planBorderElementTranslucent:null,
                  ),
                ),
              ),

              ///
              ///
              /// Контейнер для детектора
              Container(
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
                            color: isSelect?AdditionalColors.debugTranslucent:Colors.black26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ]),
    );
  }
}

double _getLen(Offset p1, Offset p2) {
  double width = (p2.dx - p1.dx).abs();
  double height = (p2.dy - p1.dy).abs();
  return sqrt(width * width + height * height);
}

// class PipelineValveWidget extends StatelessWidget {
//   final Offset p1;
//   final Offset p2;
//
//   PipelineValveWidget(this.p1, this.p2, {super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     double dragPointSize = 10.0;
//     double angle = _getAngle(p1, p2);
//     return Positioned(
//       top: min(p1.dy, p2.dy) - (dragPointSize),
//       left: min(p1.dx, p2.dx) - (dragPointSize),
//       child: Container(
//         width: (p2.dx - p1.dx).abs() + dragPointSize * 2,
//         height: (p2.dy - p1.dy).abs() + dragPointSize * 2,
//         color: Colors.black12,
//         child: Stack(
//           children: [
//             ///
//             ///
//             /// Пейнтер линии
//             CustomPaint(
//                 painter: _MyLinePainter(
//               Offset(
//                 p1.dx - min(p1.dx, p2.dx) + dragPointSize,
//                 p1.dy - min(p1.dy, p2.dy) + dragPointSize,
//               ),
//               Offset(p2.dx - min(p1.dx, p2.dx) + dragPointSize,
//                   p2.dy - min(p1.dy, p2.dy) + dragPointSize),
//             )),
//
//             ///
//             ///
//             /// первая точке
//             Positioned(
//               left: p1.dx - min(p1.dx, p2.dx) + dragPointSize / 2,
//               top: p1.dy - min(p1.dy, p2.dy) + dragPointSize / 2,
//               child: Container(
//                 width: dragPointSize,
//                 height: dragPointSize,
//                 color: AdditionalColors.planBorderElementTranslucent,
//               ),
//             ),
//
//             ///
//             ///
//             /// вторая точке
//             Positioned(
//               left: p2.dx - min(p1.dx, p2.dx) + dragPointSize / 2,
//               top: p2.dy - min(p1.dy, p2.dy) + dragPointSize / 2,
//               child: Container(
//                 width: dragPointSize,
//                 height: dragPointSize,
//                 color: AdditionalColors.planBorderElementTranslucent,
//               ),
//             ),
//
//             ///
//             ///
//             /// Контейнер для детектора
//             Transform.rotate(
//               angle: angle,
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 15.0),
//                   child: Container(
//                     width: 50,
//                     child: Expanded(
//                       child: Text("Кран"),
//                     ),
//                     color: AdditionalColors.debugTranslucent,
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

class _MyLinePainter extends CustomPainter {
  final Offset p1;

  final Offset p2;

  _MyLinePainter(this.p1, this.p2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red;
    paint.strokeWidth = 5;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
