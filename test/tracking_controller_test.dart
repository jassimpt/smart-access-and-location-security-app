import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/core/services/notification_service.dart';
import 'package:smart_access/features/authentication/controllers/authentication_controller.dart';
import 'package:smart_access/features/location/models/location_device_status.dart';
import 'package:smart_access/features/location/services/location_service.dart';
import 'package:smart_access/features/tracking/controllers/tracking_controller.dart';
import 'package:smart_access/features/tracking/models/tracking_session.dart';
import 'package:smart_access/features/tracking/services/tracking_location_service.dart';
import 'package:smart_access/features/tracking/services/tracking_storage_service.dart';
import 'package:smart_access/features/tracking/states/tracking_state.dart';

import 'helpers/authentication_fakes.dart';
import 'helpers/location_fakes.dart';
import 'helpers/tracking_fakes.dart';

void main() {
  late FakeLocationService location;
  late FakeTrackingLocationService gps;
  late MemoryTrackingStorage storage;
  late FakeNotificationService notifications;
  late ProviderContainer container;
  late DateTime now;

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      authenticationControllerProvider.overrideWith(
        UnlockedAuthenticationController.new,
      ),
      locationServiceProvider.overrideWithValue(location),
      trackingLocationServiceProvider.overrideWithValue(gps),
      trackingStorageServiceProvider.overrideWithValue(storage),
      notificationServiceProvider.overrideWithValue(notifications),
      trackingClockProvider.overrideWithValue(() => now),
    ],
  );

  Future<TrackingController> initialize() async {
    await container.read(authenticationControllerProvider.future);
    final controller = container.read(trackingControllerProvider.notifier);
    await controller.initialize();
    return controller;
  }

  TrackingState current() => container.read(trackingControllerProvider);
  Future<void> drain() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> addPoint({
    double latitude = 12.9716,
    int seconds = 0,
    double accuracy = 5,
  }) async {
    now = now.add(Duration(seconds: seconds));
    gps.controller.add(
      sampleTrackPoint(now, latitude: latitude, accuracy: accuracy),
    );
    await drain();
  }

  setUp(() {
    location = FakeLocationService();
    gps = FakeTrackingLocationService();
    storage = MemoryTrackingStorage();
    notifications = FakeNotificationService();
    now = DateTime.utc(2026, 11, 11, 8);
    container = createContainer();
  });
  tearDown(() async {
    container.dispose();
    await gps.controller.close();
    await location.changes.close();
  });

  test(
    'start is idempotent and creates exactly one foreground position listener',
    () async {
      final controller = await initialize();
      await Future.wait([
        controller.startOrResume(),
        controller.startOrResume(),
      ]);
      expect(current().isRunning, isTrue);
      expect(gps.activeListeners, 1);
      expect(gps.totalListeners, 1);
      expect(notifications.events, [TrackingNotification.started]);
      expect(storage.active, isNotNull);
    },
  );

  test(
    'accepted movement updates distance, speed, duration, and samples',
    () async {
      final controller = await initialize();
      await controller.startOrResume();
      await addPoint();
      await addPoint(latitude: 12.9726, seconds: 10);
      expect(current().session!.points.length, 2);
      expect(current().session!.distanceMetres, closeTo(111, 1));
      expect(current().speed, closeTo(11.1, 0.2));
      expect(current().elapsed, const Duration(seconds: 10));
      expect(storage.checkpoints, greaterThanOrEqualTo(2));
    },
  );

  test(
    'pause and resume exclude time away and do not connect route gaps',
    () async {
      final controller = await initialize();
      await controller.startOrResume();
      await addPoint();
      await addPoint(latitude: 12.9726, seconds: 10);
      final distance = current().session!.distanceMetres;
      await controller.pause();
      expect(gps.activeListeners, 0);
      now = now.add(const Duration(hours: 2));
      await controller.startOrResume();
      await addPoint(latitude: 13.1, seconds: 5);
      expect(current().session!.distanceMetres, distance);
      expect(current().session!.points.last.segment, 1);
      expect(current().elapsed, const Duration(seconds: 15));
      expect(gps.activeListeners, 1);
      await controller.stopAndSave();
      expect(storage.history.single.elapsedMilliseconds, 15000);
      expect(storage.history.single.status, TrackingSessionStatus.completed);
      expect(current().session, isNull);
      expect(notifications.events.last, TrackingNotification.stopped);
    },
  );

  test(
    'backgrounding pauses once and does not restart automatically on resume',
    () async {
      final controller = await initialize();
      await controller.startOrResume();
      controller.handleLifecycle(AppLifecycleState.paused);
      controller.handleLifecycle(AppLifecycleState.hidden);
      await drain();
      expect(current().session!.status, TrackingSessionStatus.paused);
      expect(gps.activeListeners, 0);
      controller.handleLifecycle(AppLifecycleState.resumed);
      await drain();
      expect(gps.activeListeners, 0);
      await controller.startOrResume();
      expect(gps.activeListeners, 1);
      expect(
        notifications.events
            .where((event) => event == TrackingNotification.paused)
            .length,
        1,
      );
    },
  );

  test('locking the app immediately stops recording', () async {
    final controller = await initialize();
    await controller.startOrResume();
    container.read(authenticationControllerProvider.notifier).lock();
    await drain();
    expect(current().isRunning, isFalse);
    expect(gps.activeListeners, 0);
    await controller.startOrResume();
    expect(gps.activeListeners, 0);
  });

  test(
    'denied location access blocks session creation and suggests Location tab',
    () async {
      location.permission = LocationPermissionStatus.denied;
      final controller = await initialize();
      await controller.startOrResume();
      expect(current().session, isNull);
      expect(current().accessProblem, isNotNull);
      expect(gps.totalListeners, 0);
      expect(storage.active, isNull);
    },
  );

  test(
    'notification denial or delivery failure never blocks recording',
    () async {
      notifications.allowed = false;
      final controller = await initialize();
      await controller.startOrResume();
      expect(current().isRunning, isTrue);
      expect(current().notificationWarning, isNotNull);
      await controller.pause();
      notifications.allowed = true;
      notifications.failShow = true;
      await controller.startOrResume();
      expect(current().isRunning, isTrue);
      expect(current().notificationWarning, isNotNull);
    },
  );

  test('recovered session stays paused until explicitly resumed', () async {
    storage.active = sampleTrackingSession(
      status: TrackingSessionStatus.running,
    );
    await initialize();
    expect(current().session!.id, 'session-a');
    expect(current().session!.status, TrackingSessionStatus.paused);
    expect(current().elapsed, const Duration(minutes: 2));
    expect(gps.totalListeners, 0);
    expect(current().message, TextConstants.trackingRecovered);
  });

  test(
    'failed initialization can be retried without overwriting existing data',
    () async {
      storage.failLoad = true;
      final controller = await initialize();
      expect(current().loadFailed, isTrue);
      await controller.startOrResume();
      expect(gps.totalListeners, 0);
      storage.failLoad = false;
      await controller.initialize();
      expect(current().initialized, isTrue);
      await controller.startOrResume();
      expect(gps.totalListeners, 1);
    },
  );

  test(
    'failed stop retains the paused session and retry archives it once',
    () async {
      final controller = await initialize();
      await controller.startOrResume();
      await addPoint();
      storage.failComplete = true;
      await controller.stopAndSave();
      expect(current().session!.status, TrackingSessionStatus.paused);
      expect(gps.activeListeners, 0);
      expect(current().storageWarning, isNotNull);
      storage.failComplete = false;
      await controller.stopAndSave();
      expect(current().session, isNull);
      expect(storage.history.length, 1);
    },
  );

  test(
    'GPS stream errors and disabled services pause recording cleanly',
    () async {
      final controller = await initialize();
      await controller.startOrResume();
      gps.controller.addError(StateError('Permission revoked'));
      await drain();
      expect(current().isRunning, isFalse);
      await controller.startOrResume();
      location.changes.add(false);
      await drain();
      expect(current().isRunning, isFalse);
      expect(gps.activeListeners, 0);
    },
  );

  test('poor or stale samples do not corrupt route metrics', () async {
    final controller = await initialize();
    await controller.startOrResume();
    await addPoint(accuracy: 200);
    expect(current().session!.points, isEmpty);
    await addPoint(seconds: 1);
    gps.controller.add(
      sampleTrackPoint(
        now.subtract(const Duration(minutes: 1)),
        latitude: 12.98,
      ),
    );
    await drain();
    expect(current().session!.points.length, 1);
    expect(current().session!.distanceMetres, 0);
  });

  test('checkpoint failure pauses and preserves the in-memory route', () async {
    final controller = await initialize();
    await controller.startOrResume();
    storage.failSave = true;
    await addPoint();
    expect(current().isRunning, isFalse);
    expect(current().session!.points.length, 1);
    expect(current().storageWarning, isNotNull);
    expect(gps.activeListeners, 0);
  });

  test(
    'serialized writes prevent a delayed checkpoint from recreating a stopped session',
    () async {
      final controller = await initialize();
      await controller.startOrResume();
      storage.pendingSave = Completer<void>();
      await addPoint();
      final stopped = controller.stopAndSave();
      await drain();
      storage.pendingSave!.complete();
      await stopped;
      expect(storage.active, isNull);
      expect(storage.history.length, 1);
      expect(storage.history.single.points.length, 1);
    },
  );

  test('an immediate stop waits for an in-progress manual pause', () async {
    final controller = await initialize();
    await controller.startOrResume();
    await addPoint();
    final paused = controller.pause();
    final stopped = controller.stopAndSave();
    await Future.wait([paused, stopped]);
    expect(storage.active, isNull);
    expect(storage.history.length, 1);
    expect(current().session, isNull);
    expect(notifications.events.last, TrackingNotification.stopped);
  });

  test('clearing completed history preserves the unfinished session', () async {
    storage.history = [sampleTrackingSession()];
    final controller = await initialize();
    await controller.startOrResume();
    final id = current().session!.id;
    await controller.clearHistory();
    expect(storage.history, isEmpty);
    expect(current().history, isEmpty);
    expect(storage.active!.id, id);
    expect(current().isRunning, isTrue);
  });
}
