import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_access/core/storage/hive_service.dart';
import 'package:smart_access/features/tracking/helpers/tracking_formatters.dart';
import 'package:smart_access/features/tracking/models/tracking_session.dart';
import 'package:smart_access/features/tracking/services/tracking_metrics_service.dart';
import 'package:smart_access/features/tracking/services/tracking_storage_service.dart';

import 'helpers/tracking_fakes.dart';

void main() {
  test(
    'Hive persists active and completed session models with route samples across reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'smart-access-tracking-test-',
      );
      try {
        Hive.init(directory.path);
        var storage = TrackingStorageService(HiveService());
        final active = sampleTrackingSession(
          id: 'active-session',
          status: TrackingSessionStatus.paused,
        );
        final completed = sampleTrackingSession(id: 'completed-session');
        await storage.saveActive(active);
        await storage.complete(completed);
        await storage.saveActive(active);
        await Hive.close();
        storage = TrackingStorageService(HiveService());
        final restored = await storage.loadActive();
        final history = await storage.loadHistory();
        expect(restored!.id, active.id);
        expect(restored.points.length, 2);
        expect(restored.points.last.latitude, active.points.last.latitude);
        expect(restored.points.first.segment, 0);
        expect(restored.elapsedMilliseconds, 120000);
        expect(history.single.id, completed.id);
        expect(history.single.distanceMetres, 111);
        await storage.clearHistory();
        expect(await storage.loadHistory(), isEmpty);
        expect((await storage.loadActive())!.id, active.id);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'archived session wins over a leftover active checkpoint after interruption',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'smart-access-tracking-recovery-',
      );
      try {
        Hive.init(directory.path);
        final storage = TrackingStorageService(HiveService());
        final active = sampleTrackingSession(
          status: TrackingSessionStatus.paused,
        );
        await storage.saveActive(active);
        await storage.complete(sampleTrackingSession());
        await storage.saveActive(active);
        expect(await storage.loadActive(), isNull);
        expect((await storage.loadHistory()).length, 1);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'metric filtering rejects stationary drift, poor accuracy, and implausible jumps',
    () {
      final metrics = TrackingMetricsService();
      final time = DateTime.utc(2026, 11, 11);
      final first = sampleTrackPoint(time);
      expect(metrics.evaluate(first, sampleTrackPoint(time)).accepted, isFalse);
      expect(
        metrics
            .evaluate(
              first,
              sampleTrackPoint(
                time.add(const Duration(seconds: 10)),
                latitude: 12.971601,
              ),
            )
            .accepted,
        isFalse,
      );
      expect(
        metrics
            .evaluate(
              first,
              sampleTrackPoint(
                time.add(const Duration(seconds: 10)),
                latitude: 12.9726,
                accuracy: 200,
              ),
            )
            .accepted,
        isFalse,
      );
      expect(
        metrics
            .evaluate(
              first,
              sampleTrackPoint(
                time.add(const Duration(seconds: 1)),
                latitude: 13.9716,
              ),
            )
            .accepted,
        isFalse,
      );
      final newSegment = metrics.evaluate(
        first,
        sampleTrackPoint(
          time.add(const Duration(hours: 1)),
          latitude: 13.9716,
          segment: 1,
        ),
      );
      expect(newSegment.accepted, isTrue);
      expect(newSegment.distance, 0);
    },
  );

  test(
    'route helpers separate pause gaps and duration does not wrap after a day',
    () {
      final session = sampleTrackingSession();
      final points = [
        ...session.points,
        sampleTrackPoint(
          session.startedAt.add(const Duration(hours: 1)),
          latitude: 13,
          segment: 1,
        ),
      ];
      final segments = trackingRouteSegments(session.copyWith(points: points));
      expect(segments.length, 2);
      expect(segments.first.length, 2);
      expect(segments.last.length, 1);
      expect(
        formatTrackingDuration(
          const Duration(hours: 25, minutes: 2, seconds: 3),
        ),
        '25:02:03',
      );
    },
  );
}
