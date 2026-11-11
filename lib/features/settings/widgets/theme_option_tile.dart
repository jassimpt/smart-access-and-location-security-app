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
        color: selected ? theme.colorScheme.primaryContainer : null,
        child: ListTile(
          enabled: onTap != null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Icon(icon),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(description),
          trailing: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
