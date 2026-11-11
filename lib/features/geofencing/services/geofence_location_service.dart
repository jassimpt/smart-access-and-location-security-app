import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/foreground_position_service.dart';
import '../../location/models/location_snapshot.dart';

final geofenceLocationServiceProvider = Provider(
  (ref) => GeofenceLocationService(ref.read(foregroundPositionServiceProvider)),
);

class GeofenceLocationService {
  GeofenceLocationService(this._positions);
  final ForegroundPositionService _positions;

  /// Receives the same foreground GPS source used by route tracking.
  Stream<LocationSnapshot> positions() => _positions.positions().map(
    (position) => LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      recordedAt: position.timestamp.toUtc(),
    ),
  );
}
