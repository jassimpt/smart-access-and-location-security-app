import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_service.dart';
import '../models/track_point_adapter.dart';
import '../models/tracking_session.dart';
import '../models/tracking_session_adapter.dart';

final trackingStorageServiceProvider = Provider(
  (ref) => TrackingStorageService(ref.read(hiveServiceProvider)),
);

class TrackingStorageService {
  TrackingStorageService(this._hive);
  final HiveService _hive;
  Box<TrackingSession>? _box;
  static const _activeKey = 'active';

  /// Opens the tracking box with both typed Hive adapters registered.
  Future<Box<TrackingSession>> _open() async {
    if (_box?.isOpen ?? false) return _box!;
    _hive.registerAdapter(TrackPointAdapter());
    _hive.registerAdapter(TrackingSessionAdapter());
    return _box = await _hive.openBox<TrackingSession>('tracking_v1');
  }

  /// Restores an unfinished session while ignoring an already archived copy.
  Future<TrackingSession?> loadActive() async {
    final box = await _open();
    final active = box.get(_activeKey);
    if (active == null) return null;
    if (box.containsKey(active.id) ||
        active.status == TrackingSessionStatus.completed) {
      await box.delete(_activeKey);
      return null;
    }
    return active;
  }

  /// Returns completed sessions with the most recent first.
  Future<List<TrackingSession>> loadHistory() async {
    final box = await _open();
    final sessions = box.keys
        .where((key) => key != _activeKey)
        .map((key) => box.get(key)!)
        .where((session) => session.status == TrackingSessionStatus.completed)
        .toList();
    sessions.sort(
      (first, second) => second.startedAt.compareTo(first.startedAt),
    );
    return List.unmodifiable(sessions);
  }

  /// Writes a recoverable active-session checkpoint.
  Future<void> saveActive(TrackingSession session) async =>
      (await _open()).put(_activeKey, session);

  /// Archives the completed record before removing its active checkpoint.
  Future<void> complete(TrackingSession session) async {
    final box = await _open();
    await box.put(session.id, session);
    await box.delete(_activeKey);
  }

  /// Clears completed history while preserving the unfinished session.
  Future<void> clearHistory() async {
    final box = await _open();
    await box.deleteAll(box.keys.where((key) => key != _activeKey).toList());
  }
}
