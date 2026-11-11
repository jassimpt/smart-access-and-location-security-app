import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_device_status.dart';
import '../models/location_snapshot.dart';

final locationServiceProvider = Provider((ref) => LocationService());

class LocationService {
  /// Checks location services and permission without showing a permission prompt.
  Future<LocationDeviceStatus> checkStatus() async => LocationDeviceStatus(
    serviceEnabled: await Geolocator.isLocationServiceEnabled(),
    permission: _mapPermission(await Geolocator.checkPermission()),
  );

  /// Requests foreground location access after the contextual explanation.
  Future<LocationPermissionStatus> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  /// Gets a single GPS fix with a bounded wait and no background tracking.
  Future<LocationSnapshot> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    bool? approximate;
    try {
      approximate =
          await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.reduced;
    } catch (_) {
      approximate = null;
    }
    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      recordedAt: position.timestamp.toUtc(),
      isApproximate: approximate,
    );
  }

  /// Watches GPS service changes without subscribing to position updates.
  Stream<bool> serviceChanges() => Geolocator.getServiceStatusStream()
      .map((status) => status == ServiceStatus.enabled)
      .distinct();

  /// Opens the app permission settings.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens device location settings where supported by the platform.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Measures distance locally between two coordinates.
  double distanceBetween(LocationSnapshot first, LocationSnapshot second) =>
      Geolocator.distanceBetween(
        first.latitude,
        first.longitude,
        second.latitude,
        second.longitude,
      );

  /// Converts platform permissions into the feature's access states.
  LocationPermissionStatus _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationPermissionStatus.granted,
        LocationPermission.deniedForever =>
          LocationPermissionStatus.permanentlyDenied,
        _ => LocationPermissionStatus.denied,
      };
}
