import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/text_constants.dart';
import '../constants/tracking_export_constants.dart';
import '../models/tracking_export_file.dart';
import '../models/tracking_export_format.dart';
import '../models/tracking_session.dart';
import 'tracking_export_serializer.dart';

final trackingExportServiceProvider = Provider(
  (ref) => TrackingExportService(),
);

class TrackingExportService {
  /// Prepares the export off the UI isolate and expires only this feature's old files.
  Future<File> prepare(
    List<TrackingSession> history,
    TrackingExportFormat format,
  ) async {
    final now = DateTime.now().toUtc();
    final export = await compute(_encodeHistory, (history, format, now));
    final temporary = await getTemporaryDirectory();
    final directory = Directory(
      '${temporary.path}/${TrackingExportConstants.cacheDirectory}',
    );
    await directory.create(recursive: true);
    await _removeExpiredFiles(directory, now);
    final file = File('${directory.path}/${export.name}');
    return file.writeAsBytes(export.bytes, flush: true);
  }

  /// Opens the native file-sharing sheet with a valid anchor for iPhones and iPads.
  Future<ShareResultStatus> share(
    File file,
    TrackingExportFormat format,
    Rect origin,
  ) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: format.mimeType)],
        title: TextConstants.exportHistory,
        subject: TextConstants.exportHistory,
        sharePositionOrigin: origin,
      ),
    );
    return result.status;
  }

  /// Removes an unshared export when preparation finishes after the app has locked.
  Future<void> discard(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      return;
    }
  }

  /// Retains recent exports so receiving apps can finish reading their attachments.
  Future<void> _removeExpiredFiles(Directory directory, DateTime now) async {
    try {
      await for (final entry in directory.list(followLinks: false)) {
        if (entry is! File ||
            !entry.uri.pathSegments.last.startsWith(
              TrackingExportConstants.filePrefix,
            )) {
          continue;
        }
        final modified = (await entry.stat()).modified.toUtc();
        if (now.difference(modified) > TrackingExportConstants.cacheRetention) {
          await discard(entry);
        }
      }
    } on FileSystemException {
      return;
    }
  }
}

/// Encodes complete history in a worker isolate to keep long exports responsive.
TrackingExportFile _encodeHistory(
  (List<TrackingSession>, TrackingExportFormat, DateTime) input,
) => const TrackingExportSerializer().encode(
  input.$1,
  input.$2,
  exportedAt: input.$3,
);
