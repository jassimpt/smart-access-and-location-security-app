import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/app/app.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/core/services/notification_service.dart';
import 'package:smart_access/core/storage/hive_service.dart';
import 'package:smart_access/core/storage/preferences_service.dart';
import 'package:smart_access/features/authentication/controllers/authentication_controller.dart';
import 'package:smart_access/features/location/services/location_service.dart';
import 'package:smart_access/features/location/widgets/map_tile_layer.dart';
import 'package:smart_access/features/tracking/controllers/tracking_controller.dart';
import 'package:smart_access/features/tracking/models/tracking_session.dart';
import 'package:smart_access/features/tracking/services/tracking_location_service.dart';
import 'package:smart_access/features/tracking/services/tracking_storage_service.dart';

import 'helpers/authentication_fakes.dart';
import 'helpers/location_fakes.dart';
import 'helpers/tracking_fakes.dart';
import 'widget_test.dart' show MemoryPreferences, TestHiveService;

Future<void> launchTracking(
  WidgetTester tester,
  MemoryTrackingStorage storage,
  FakeTrackingLocationService gps,
  FakeLocationService location,
  DateTime Function() now,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(MemoryPreferences()),
        hiveServiceProvider.overrideWithValue(TestHiveService()),
        authenticationControllerProvider.overrideWith(
          UnlockedAuthenticationController.new,
        ),
        locationServiceProvider.overrideWithValue(location),
        trackingLocationServiceProvider.overrideWithValue(gps),
        trackingStorageServiceProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        trackingClockProvider.overrideWithValue(now),
        mapTileProviderFactoryProvider.overrideWithValue(
          OfflineTestTileProvider.new,
        ),
      ],
      child: const SmartAccess(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(TextConstants.tracking).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('records a route, stops, and opens the saved session details', (
    tester,
  ) async {
    final storage = MemoryTrackingStorage();
    final gps = FakeTrackingLocationService();
    final location = FakeLocationService();
    var now = DateTime.utc(2026, 11, 11, 8);
    addTearDown(gps.controller.close);
    addTearDown(location.changes.close);
    await launchTracking(tester, storage, gps, location, () => now);
    await tester.ensureVisible(find.text(TextConstants.startTracking));
    await tester.tap(find.text(TextConstants.startTracking));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    gps.controller.add(sampleTrackPoint(now));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    now = now.add(const Duration(seconds: 10));
    gps.controller.add(sampleTrackPoint(now, latitude: 12.9726));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text(TextConstants.trackingActive), findsOneWidget);
    expect(find.text(TextConstants.routePreview), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(TextConstants.stopTracking));
    await tester.tap(find.text(TextConstants.stopTracking));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(storage.history.length, 1);
    expect(gps.activeListeners, 0);
    await tester.tap(find.text(TextConstants.viewHistory));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.trackingHistory), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text(TextConstants.sessionDetails), findsOneWidget);
    expect(find.text(TextConstants.routePreview), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'history deletion requires confirmation and keeps an unfinished session',
    (tester) async {
      final storage = MemoryTrackingStorage()
        ..history = [sampleTrackingSession()]
        ..active = sampleTrackingSession(
          id: 'unfinished',
          status: TrackingSessionStatus.paused,
        );
      final gps = FakeTrackingLocationService();
      final location = FakeLocationService();
      addTearDown(gps.controller.close);
      addTearDown(location.changes.close);
      await launchTracking(
        tester,
        storage,
        gps,
        location,
        () => DateTime.utc(2026, 11, 11, 8),
      );
      await tester.ensureVisible(find.text(TextConstants.viewHistory));
      await tester.tap(find.text(TextConstants.viewHistory));
      await tester.pumpAndSettle();
      await tester.tap(find.text(TextConstants.clearHistory));
      await tester.pumpAndSettle();
      expect(
        find.text(TextConstants.clearTrackingHistoryTitle),
        findsOneWidget,
      );
      await tester.tap(find.text(TextConstants.cancel));
      await tester.pumpAndSettle();
      expect(storage.history.length, 1);
      await tester.tap(find.text(TextConstants.clearHistory));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, TextConstants.clearHistory),
      );
      await tester.pumpAndSettle();
      expect(storage.history, isEmpty);
      expect(storage.active!.id, 'unfinished');
      expect(find.text(TextConstants.historyEmptyTitle), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('tracking and history fit $size with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final storage = MemoryTrackingStorage()
        ..active = sampleTrackingSession(status: TrackingSessionStatus.paused)
        ..history = [sampleTrackingSession(id: 'history')];
      final gps = FakeTrackingLocationService();
      final location = FakeLocationService();
      addTearDown(gps.controller.close);
      addTearDown(location.changes.close);
      await launchTracking(
        tester,
        storage,
        gps,
        location,
        () => DateTime.utc(2026, 11, 11, 8),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(TextConstants.routePreview));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(TextConstants.viewHistory));
      await tester.tap(find.text(TextConstants.viewHistory));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byIcon(Icons.chevron_right_rounded));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
