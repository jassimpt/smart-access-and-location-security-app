import 'package:flutter/material.dart';

class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    required this.main,
    required this.aside,
    this.breakpoint = 880,
    super.key,
  });
  final Widget main;
  final Widget aside;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= breakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: main),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: aside),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [main, const SizedBox(height: 16), aside],
      );
    },
  );
}
