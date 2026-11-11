import 'dart:async';

import 'package:smart_access/core/services/notification_service.dart';
import 'package:smart_access/features/tracking/models/track_point.dart';
import 'package:smart_access/features/tracking/models/tracking_session.dart';
import 'package:smart_access/features/tracking/services/tracking_location_service.dart';
import 'package:smart_access/features/tracking/services/tracking_storage_service.dart';

TrackPoint sampleTrackPoint(
  DateTime time, {
  double latitude = 12.9716,
  double longitude = 77.5946,
  double accuracy = 5,
  int segment = 0,
}) => TrackPoint(
  latitude: latitude,
  longitude: longitude,
  accuracy: accuracy,
  recordedAt: time,
  segment: segment,
);

TrackingSession sampleTrackingSession({
  String id = 'session-a',
  TrackingSessionStatus status = TrackingSessionStatus.completed,
}) {
  final time = DateTime.utc(2026, 11, 11, 8);
  return TrackingSession(
    id: id,
    startedAt: time,
    status: status,
    endedAt: status == TrackingSessionStatus.completed
        ? time.add(const Duration(minutes: 2))
        : null,
    elapsedMilliseconds: 120000,
    distanceMetres: 111,
    points: [
      sampleTrackPoint(time),
      sampleTrackPoint(
        time.add(const Duration(seconds: 10)),
        latitude: 12.9726,
      ),
    ],
  );
}

class FakeTrackingLocationService implements TrackingLocationService {
  FakeTrackingLocationService() {
    controller = StreamController<TrackPoint>.broadcast(
      onListen: () {
        activeListeners++;
        totalListeners++;
      },
      onCancel: () => activeListeners--,
    );
  }
  late final StreamController<TrackPoint> controller;
  int activeListeners = 0;
  int totalListeners = 0;
  @override
  Stream<TrackPoint> positions() => controller.stream;
}

class MemoryTrackingStorage implements TrackingStorageService {
  TrackingSession? active;
  List<TrackingSession> history = [];
  bool failLoad = false;
  bool failSave = false;
  bool failComplete = false;
  bool failClear = false;
  Completer<void>? pendingSave;
  int checkpoints = 0;

  @override
  Future<TrackingSession?> loadActive() async {
    if (failLoad) throw StateError('Load failed');
    return active;
  }

  @override
  Future<List<TrackingSession>> loadHistory() async {
    if (failLoad) throw StateError('Load failed');
    return List.unmodifiable(history);
  }

  @override
  Future<void> saveActive(TrackingSession session) async {
    checkpoints++;
    if (pendingSave != null) await pendingSave!.future;
    if (failSave) throw StateError('Save failed');
    active = session;
  }

  @override
  Future<void> complete(TrackingSession session) async {
    if (failComplete) throw StateError('Complete failed');
    history = [session, ...history.where((item) => item.id != session.id)];
    active = null;
  }

  @override
  Future<void> clearHistory() async {
    if (failClear) throw StateError('Clear failed');
    history = [];
  }
}

class FakeNotificationService implements NotificationService {
  bool allowed = true;
  bool failShow = false;
  final events = <TrackingNotification>[];
  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<void> showTrackingUpdate(TrackingNotification status) async {
    if (failShow) throw StateError('Notification failed');
    events.add(status);
  }
}
