import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_service.dart';
import '../models/geofence.dart';
import '../models/geofence_adapter.dart';

final geofenceStorageServiceProvider = Provider(
  (ref) => GeofenceStorageService(ref.read(hiveServiceProvider)),
);

class GeofenceStorageService {
  GeofenceStorageService(this._hive);
  final HiveService _hive;
  Box<Geofence>? _box;

  /// Opens the typed geofence box after registering its adapter.
  Future<Box<Geofence>> _open() async {
    if (_box?.isOpen ?? false) return _box!;
    _hive.registerAdapter(GeofenceAdapter());
    return _box = await _hive.openBox<Geofence>('geofences_v1');
  }

  /// Loads all saved areas with the most recently edited first.
  Future<List<Geofence>> load() async {
    final fences = (await _open()).values.toList();
    fences.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return List.unmodifiable(fences);
  }

  /// Creates or replaces one geofence without changing other areas.
  Future<void> save(Geofence fence) async =>
      (await _open()).put(fence.id, fence);

  /// Deletes only the selected geofence.
  Future<void> delete(String id) async => (await _open()).delete(id);
}
