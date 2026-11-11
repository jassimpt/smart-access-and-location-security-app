import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../location/models/location_snapshot.dart';
import '../models/geofence.dart';
import '../models/geofence_event.dart';

final geofenceBoundaryServiceProvider = Provider(
  (ref) => GeofenceBoundaryService(),
);

class GeofenceBoundaryService {
  /// Holds the previous state when GPS uncertainty overlaps the boundary.
  GeofencePresence evaluate(
    Geofence fence,
    LocationSnapshot position,
    GeofencePresence previous,
  ) {
    if (position.accuracy <= 0 ||
        position.accuracy > min(75, fence.radiusMetres / 2)) {
      return previous;
    }
    final distance = Geolocator.distanceBetween(
      fence.latitude,
      fence.longitude,
      position.latitude,
      position.longitude,
    );
    final margin = max(10.0, position.accuracy);
    if (distance + margin < fence.radiusMetres) return GeofencePresence.inside;
    if (distance - margin > fence.radiusMetres) return GeofencePresence.outside;
    return previous;
  }
}
