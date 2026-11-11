import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/foreground_position_service.dart';

import '../models/track_point.dart';

final trackingLocationServiceProvider = Provider(
  (ref) => TrackingLocationService(ref.read(foregroundPositionServiceProvider)),
);

class TrackingLocationService {
  TrackingLocationService(this._positions);
  final ForegroundPositionService _positions;

  /// Streams foreground GPS positions without configuring a background service.
  Stream<TrackPoint> positions() => _positions.positions().map(
    (position) => TrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      recordedAt: position.timestamp.toUtc(),
      speed: position.speed.isFinite && position.speed > 0 ? position.speed : 0,
    ),
  );
}
