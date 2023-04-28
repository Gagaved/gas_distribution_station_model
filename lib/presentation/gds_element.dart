import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/presentation/styles.dart';

double _getAngle(Offset p1, Offset p2) {
  double x1 = p1.dx - min(p1.dx, p2.dx);
  double y1 = p1.dy - min(p1.dy, p2.dy);
  double x2 = p2.dx - min(p1.dx, p2.dx);
  double y2 = p2.dy - min(p1.dy, p2.dy);
  double k = (y2 - y1) / (x2 - x1);
  print("x1:${x1}\n y1:${y1}");
  print("x2:${x2}\n y2:${y2}");
  double result = pi - atan2(x2 - x1, y2 - y1);
  print(k);
  print("angle:${result}");
  return result;
}

class PipelineSegmentWidget extends StatelessWidget {
  final int id;
  final Offset p1;
  final Offset p2;

  PipelineSegmentWidget({required this.id, required this.p1, required this.p2, super.key});

  @override
  Widget build(BuildContext context) {
    double dragPointSize = 10.0;
    double angle = _getAngle(p1, p2);
    return Positioned(
      top: min(p1.dy, p2.dy) - (dragPointSize),
      left: min(p1.dx, p2.dx) - (dragPointSize),
      child: Container(
        width: (p2.dx - p1.dx).abs() + dragPointSize * 2,
        height: (p2.dy - p1.dy).abs() + dragPointSize * 2,
        color: Colors.black12,
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
              child: Container(
                width: dragPointSize,
                height: dragPointSize,
                color: AdditionalColors.planBorderElementTranslucent,
              ),
            ),

            ///
            ///
            /// вторая точке
            Positioned(
              left: p2.dx - min(p1.dx, p2.dx) + dragPointSize / 2,
              top: p2.dy - min(p1.dy, p2.dy) + dragPointSize / 2,
              child: Container(
                width: dragPointSize,
                height: dragPointSize,
                color: AdditionalColors.planBorderElementTranslucent,
              ),
            ),

            ///
            ///
            /// Контейнер для детектора
            Transform.rotate(
              angle: angle,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: GestureDetector(
                    onTap: (){
                      context.read<GdsPageBloc>().add(GdsSelectElementEvent(id));
                    },
                    child: Container(
                      width: 10,
                      color: AdditionalColors.debugTranslucent,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
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
    print("---");
    print(p1.dx);
    print(p1.dy);
    print(p2.dx);
    print(p2.dy);
    print("---");
    final paint = Paint()..color = Colors.red;
    paint.strokeWidth = 5;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
