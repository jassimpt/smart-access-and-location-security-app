import 'dart:convert';
import 'dart:typed_data';

import '../constants/tracking_export_constants.dart';
import '../models/tracking_export_file.dart';
import '../models/tracking_export_format.dart';
import '../models/tracking_session.dart';

class TrackingExportSerializer {
  const TrackingExportSerializer();

  /// Serializes completed journeys with UTC timestamps and explicit metric units.
  TrackingExportFile encode(
    List<TrackingSession> history,
    TrackingExportFormat format, {
    required DateTime exportedAt,
  }) {
    final sessions = history
        .where((session) => session.status == TrackingSessionStatus.completed)
        .toList(growable: false);
    final timestamp = exportedAt.toUtc();
    final content = switch (format) {
      TrackingExportFormat.csv => _csv(sessions),
      TrackingExportFormat.json => _json(sessions, timestamp),
    };
    final stamp = timestamp.toIso8601String().replaceAll(':', '-');
    return TrackingExportFile(
      name: '${TrackingExportConstants.filePrefix}_$stamp.${format.extension}',
      bytes: Uint8List.fromList(utf8.encode(content)),
      format: format,
    );
  }

  /// Includes full route samples and pause segments in a versioned JSON document.
  String _json(List<TrackingSession> sessions, DateTime exportedAt) =>
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': TrackingExportConstants.schemaVersion,
        'exported_at_utc': exportedAt.toIso8601String(),
        'session_count': sessions.length,
        'sessions': [
          for (final session in sessions)
            {
              'id': session.id,
              'status': session.status.name,
              'started_at_utc': session.startedAt.toUtc().toIso8601String(),
              'ended_at_utc': session.endedAt!.toUtc().toIso8601String(),
              'duration_milliseconds': session.elapsedMilliseconds,
              'distance_metres': session.distanceMetres,
              'point_count': session.points.length,
              'points': [
                for (final point in session.points)
                  {
                    'recorded_at_utc': point.recordedAt
                        .toUtc()
                        .toIso8601String(),
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                    'accuracy_metres': point.accuracy,
                    'speed_metres_per_second': point.speed,
                    'segment': point.segment,
                  },
              ],
            },
        ],
      });

  /// Writes one CSV row per route sample, retaining sessions with no GPS points.
  String _csv(List<TrackingSession> sessions) {
    final output = StringBuffer('\uFEFF');
    _writeCsvRow(output, TrackingExportConstants.csvHeaders);
    for (final session in sessions) {
      final summary = <Object?>[
        session.id,
        session.startedAt.toUtc().toIso8601String(),
        session.endedAt!.toUtc().toIso8601String(),
        session.elapsedMilliseconds,
        session.distanceMetres,
        session.points.length,
      ];
      if (session.points.isEmpty) {
        _writeCsvRow(output, [...summary, ...List<String>.filled(7, '')]);
      } else {
        for (final (index, point) in session.points.indexed) {
          _writeCsvRow(output, [
            ...summary,
            index + 1,
            point.recordedAt.toUtc().toIso8601String(),
            point.latitude,
            point.longitude,
            point.accuracy,
            point.speed,
            point.segment,
          ]);
        }
      }
    }
    return output.toString();
  }

  /// Escapes CSV delimiters, quotes and line breaks without changing numeric values.
  void _writeCsvRow(StringBuffer output, List<Object?> values) {
    output.writeAll(
      values.map((value) {
        final text = value?.toString() ?? '';
        return text.contains(RegExp('[,"\r\n]'))
            ? '"${text.replaceAll('"', '""')}"'
            : text;
      }),
      ',',
    );
    output.write('\r\n');
  }
}
