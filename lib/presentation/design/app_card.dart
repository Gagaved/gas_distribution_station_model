import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.title, this.subTitle});
  final Widget child;
  final String? title;
  final Widget? subTitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          width: 1,
          color: Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$title',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (subTitle != null)
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: subTitle,
              ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
