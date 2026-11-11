import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track_point.dart';

final trackingLocationServiceProvider = Provider(
  (ref) => TrackingLocationService(),
);

class TrackingLocationService {
  /// Streams foreground GPS positions without configuring a background service.
  Stream<TrackPoint> positions() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).map(
        (position) => TrackPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          recordedAt: position.timestamp.toUtc(),
          speed: position.speed.isFinite && position.speed > 0
              ? position.speed
              : 0,
        ),
      );
}
