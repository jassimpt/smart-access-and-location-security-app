import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:smart_access/features/location/models/location_device_status.dart';
import 'package:smart_access/features/location/models/location_snapshot.dart';
import 'package:smart_access/features/location/services/address_service.dart';
import 'package:smart_access/features/location/services/location_service.dart';
import 'package:smart_access/features/location/services/location_storage_service.dart';

LocationSnapshot sampleLocation({
  double latitude = 12.9716,
  double longitude = 77.5946,
  String? address,
}) => LocationSnapshot(
  latitude: latitude,
  longitude: longitude,
  accuracy: 8.5,
  recordedAt: DateTime.utc(2026, 11, 11, 8),
  isApproximate: false,
  address: address,
);

class FakeLocationService extends LocationService {
  FakeLocationService() {
    changes = StreamController<bool>.broadcast(
      onListen: () {
        activeListeners++;
        totalListeners++;
      },
      onCancel: () => activeListeners--,
    );
  }
  late final StreamController<bool> changes;
  int activeListeners = 0;
  int totalListeners = 0;
  int permissionRequests = 0;
  int positionRequests = 0;
  bool serviceEnabled = true;
  LocationPermissionStatus permission = LocationPermissionStatus.granted;
  LocationPermissionStatus requestOutcome = LocationPermissionStatus.granted;
  LocationSnapshot position = sampleLocation();
  Completer<LocationSnapshot>? pending;
  Object? positionError;
  bool settingsOpen = true;

  @override
  Future<LocationDeviceStatus> checkStatus() async => LocationDeviceStatus(
    serviceEnabled: serviceEnabled,
    permission: permission,
  );

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    permissionRequests++;
    return permission = requestOutcome;
  }

  @override
  Future<LocationSnapshot> currentPosition() async {
    positionRequests++;
    if (positionError != null) throw positionError!;
    return pending?.future ?? Future.value(position);
  }

  @override
  Stream<bool> serviceChanges() => changes.stream;

  @override
  Future<bool> openAppSettings() async => settingsOpen;

  @override
  Future<bool> openLocationSettings() async => settingsOpen;
}

class MemoryLocationStorage implements LocationStorageService {
  LocationSnapshot? saved;
  bool failRead = false;
  bool failWrite = false;
  int saves = 0;

  @override
  Future<LocationSnapshot?> loadLatest() async {
    if (failRead) throw StateError('Cache read failed');
    return saved;
  }

  @override
  Future<void> saveLatest(LocationSnapshot snapshot) async {
    if (failWrite) throw StateError('Cache write failed');
    saves++;
    saved = snapshot;
  }
}

class FakeAddressService extends AddressService {
  String? address = 'Bengaluru, Karnataka, India';
  int calls = 0;
  @override
  Future<String?> resolve(LocationSnapshot location) async {
    calls++;
    return address;
  }
}

class OfflineTestTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}
