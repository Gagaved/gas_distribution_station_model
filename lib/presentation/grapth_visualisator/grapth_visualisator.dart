import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: InfiniteSurfaceWidget(
//         children: [
//           PositionedWidget(offset: Offset(200, 200), child: Text('Widget 2')),
//         ],
//       ),
//     );
//   }
// }

class InfiniteSurface extends StatefulWidget {
  final List<Widget> children;

  const InfiniteSurface(
      {super.key,
      required this.children,
      required this.transformationController});
  final TransformationController transformationController;
  @override
  InfiniteSurfaceState createState() => InfiniteSurfaceState();
}

class InfiniteSurfaceState extends State<InfiniteSurface> {
  Offset _currentOffset = Offset.zero;
  final kDrag = 1e-200;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DeferredPointerHandler(
          child: InteractiveViewer(
            interactionEndFrictionCoefficient: kDrag,
            scaleFactor: 400,
            transformationController: widget.transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 10.0,
            onInteractionUpdate: (ScaleUpdateDetails details) {
              setState(() {
                _currentOffset += details.focalPointDelta;
              });
            },
            //interactionEndFrictionCoefficient: 100,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: InfiniteSpacePainter(
                      widget.transformationController.value, _currentOffset),
                ),
                ...widget.children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfiniteSpacePainter extends CustomPainter {
  final Matrix4 transformation;
  final Offset offset;

  InfiniteSpacePainter(this.transformation, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    // Get the visible rectangle after transformation
    Rect visibleRect = Offset.zero & size;
    Rect transformedVisibleRect =
        MatrixUtils.inverseTransformRect(transformation, visibleRect);
    // Calculate the current scale
    double scale = transformation.getMaxScaleOnAxis();
    double step = _calculateStepSize(scale);

    Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;
    final startX = (transformedVisibleRect.left / step) * step -
        transformedVisibleRect.left % step;
    for (double x = startX; x < transformedVisibleRect.right; x += step) {
      paint.color = x.toInt() == 0 ? Colors.black26 : Colors.black12;
      paint.strokeWidth = x.toInt() == 0 ? 2.0 / scale : 1.0 / scale;
      canvas.drawLine(Offset(x, transformedVisibleRect.top - step),
          Offset(x, transformedVisibleRect.bottom), paint);
    }
    final startY = (transformedVisibleRect.top / step) * step -
        transformedVisibleRect.top % step;
    for (double y = startY; y < transformedVisibleRect.bottom; y += step) {
      paint.color = y.toInt() == 0 ? Colors.black26 : Colors.black12;
      paint.strokeWidth = y.toInt() == 0 ? 2.0 / scale : 1.0 / scale;
      canvas.drawLine(Offset(transformedVisibleRect.left, y),
          Offset(transformedVisibleRect.right, y), paint);
    }

    // Draw coordinates within the visible rectangle
    paint.color = Colors.black;
    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (double x = startX; x < transformedVisibleRect.right; x += step) {
      textPainter.text = TextSpan(
        text: x.toInt().toString(),
        style: TextStyle(color: Colors.black, fontSize: 12 / scale),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, transformedVisibleRect.top));
    }
    for (double y = startY; y < transformedVisibleRect.bottom; y += step) {
      textPainter.text = TextSpan(
        text: y.toInt().toString(),
        style: TextStyle(color: Colors.black, fontSize: 12 / scale),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(transformedVisibleRect.left, y));
    }

    // Apply transformation
    canvas.transform(transformation.storage);
  }

  double _calculateStepSize(double scale) {
    // Adjust the step size based on the scale
    if (scale > 5) {
      return 10;
    } else if (scale > 2) {
      return 20;
    } else if (scale > 1) {
      return 50;
    } else if (scale > 0.5) {
      return 100;
    } else {
      return 200;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
