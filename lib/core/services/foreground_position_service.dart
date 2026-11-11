import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final foregroundPositionServiceProvider = Provider(
  (ref) => ForegroundPositionService(),
);

class ForegroundPositionService {
  /// Uses the platform's shared foreground stream with consistent settings across features.
  Stream<Position> positions() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
}
