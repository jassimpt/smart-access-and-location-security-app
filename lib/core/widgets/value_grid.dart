import 'package:flutter/material.dart';

class ValueGrid extends StatelessWidget {
  const ValueGrid({required this.children, this.minimumWidth = 140, super.key});
  final List<Widget> children;
  final double minimumWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns = (constraints.maxWidth / (minimumWidth * scale))
          .floor()
          .clamp(1, 3);
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
