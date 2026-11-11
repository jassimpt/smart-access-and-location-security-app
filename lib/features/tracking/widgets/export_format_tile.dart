import 'package:flutter/material.dart';

import '../models/tracking_export_format.dart';

class ExportFormatTile extends StatelessWidget {
  const ExportFormatTile({
    required this.format,
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final TrackingExportFormat format;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: scheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pop(format),
      ),
    );
  }
}
