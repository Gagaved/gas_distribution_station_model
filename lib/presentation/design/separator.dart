import 'package:flutter/material.dart';

class Separator extends StatelessWidget {
  const Separator.horizontal({
    super.key,
    this.color = Colors.black12,
    required this.height,
  }) : width = double.infinity;
  const Separator.vertical(
      {super.key, this.color = Colors.black12, required this.width})
      : height = double.infinity;
  final Color color;
  final double height;
  final double width;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      height: height,
      width: width,
    );
  }
}
