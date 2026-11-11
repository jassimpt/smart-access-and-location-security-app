import 'package:flutter/material.dart';

class DashboardStatusRow extends StatelessWidget {
  const DashboardStatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}
