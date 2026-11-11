import 'package:flutter/material.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.shield_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
