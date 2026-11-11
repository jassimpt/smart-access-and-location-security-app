import 'dart:typed_data';

import 'tracking_export_format.dart';

class TrackingExportFile {
  const TrackingExportFile({
    required this.name,
    required this.bytes,
    required this.format,
  });

  final String name;
  final Uint8List bytes;
  final TrackingExportFormat format;
}
