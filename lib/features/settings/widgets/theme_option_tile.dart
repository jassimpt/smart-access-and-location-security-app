import 'package:flutter/material.dart';

class ThemeOptionTile extends StatelessWidget {
  const ThemeOptionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      child: Card(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: .06)
            : null,
        child: ListTile(
          enabled: onTap != null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: .12)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(description, style: theme.textTheme.bodySmall),
          trailing: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            size: 20,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
