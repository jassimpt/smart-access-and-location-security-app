import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/section_header.dart';
import '../models/tracking_export_format.dart';
import 'export_format_tile.dart';

class TrackingExportSheet extends StatelessWidget {
  const TrackingExportSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: TextConstants.exportHistory,
            subtitle: TextConstants.exportDescription,
          ),
          const ExportFormatTile(
            format: TrackingExportFormat.csv,
            title: TextConstants.exportCsv,
            description: TextConstants.exportCsvDescription,
            icon: Icons.table_chart_outlined,
          ),
          const SizedBox(height: 12),
          const ExportFormatTile(
            format: TrackingExportFormat.json,
            title: TextConstants.exportJson,
            description: TextConstants.exportJsonDescription,
            icon: Icons.data_object_rounded,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(TextConstants.cancel),
          ),
        ],
      ),
    ),
  );
}
