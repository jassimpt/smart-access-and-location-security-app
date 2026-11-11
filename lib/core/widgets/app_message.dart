import 'package:flutter/material.dart';

class AppMessage extends StatelessWidget {
  const AppMessage({
    required this.title,
    this.description,
    this.icon = Icons.info_outline_rounded,
    this.action,
    super.key,
  });

  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                const SizedBox(height: 12),
                Text(description!, textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}
