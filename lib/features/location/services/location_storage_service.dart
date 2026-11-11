import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_service.dart';
import '../models/location_snapshot.dart';
import '../models/location_snapshot_adapter.dart';

final locationStorageServiceProvider = Provider(
  (ref) => LocationStorageService(ref.read(hiveServiceProvider)),
);

class LocationStorageService {
  LocationStorageService(this._hive);

  final HiveService _hive;
  Box<LocationSnapshot>? _box;
  static const _boxName = 'location_v1';
  static const _latestKey = 'latest';

  /// Opens the typed location box after registering its adapter.
  Future<Box<LocationSnapshot>> _open() async {
    if (_box?.isOpen ?? false) return _box!;
    _hive.registerAdapter(LocationSnapshotAdapter());
    return _box = await _hive.openBox<LocationSnapshot>(_boxName);
  }

  /// Restores the last known position and its matching address.
  Future<LocationSnapshot?> loadLatest() async =>
      (await _open()).get(_latestKey);

  /// Saves a location snapshot for offline use across app restarts.
  Future<void> saveLatest(LocationSnapshot snapshot) async =>
      (await _open()).put(_latestKey, snapshot);
}
