import '../../authentication/states/authentication_state.dart';
import '../../geofencing/states/geofence_state.dart';
import '../../location/states/location_state.dart';
import '../../location/models/location_snapshot.dart';
import '../../tracking/states/tracking_state.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.security,
    required this.location,
    required this.tracking,
    required this.areas,
  });

  final AuthenticationState? security;
  final LocationState location;
  final TrackingState tracking;
  final GeofenceState areas;

  /// Selects the newest known fix without attaching an address from another position.
  ({LocationSnapshot snapshot, bool isCached})? get position {
    ({LocationSnapshot snapshot, bool isCached})? latest;
    if (location.snapshot != null) {
      latest = (snapshot: location.snapshot!, isCached: location.isCached);
    }
    final point =
        tracking.session?.points.lastOrNull ??
        tracking.history.firstOrNull?.points.lastOrNull;
    final candidates = [
      if (point != null)
        (
          snapshot: LocationSnapshot(
            latitude: point.latitude,
            longitude: point.longitude,
            accuracy: point.accuracy,
            recordedAt: point.recordedAt,
          ),
          isCached:
              !tracking.isRunning || tracking.session?.points.isEmpty != false,
        ),
      if (areas.lastPosition != null)
        (snapshot: areas.lastPosition!, isCached: !areas.isMonitoring),
    ];
    for (final candidate in candidates) {
      if (latest == null ||
          candidate.snapshot.recordedAt.isAfter(latest.snapshot.recordedAt) ||
          (candidate.snapshot.recordedAt == latest.snapshot.recordedAt &&
              !candidate.isCached &&
              latest.isCached)) {
        latest = candidate;
      }
    }
    return latest;
  }

  bool get hasStorageFailure => tracking.loadFailed || areas.loadFailed;
}
