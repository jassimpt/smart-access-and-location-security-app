import 'track_point.dart';

enum TrackingSessionStatus { running, paused, completed }

class TrackingSession {
  TrackingSession({
    required this.id,
    required this.startedAt,
    required this.status,
    this.endedAt,
    this.elapsedMilliseconds = 0,
    this.distanceMetres = 0,
    this.segment = 0,
    List<TrackPoint> points = const [],
  }) : points = List.unmodifiable(points) {
    if (id.isEmpty ||
        elapsedMilliseconds < 0 ||
        !distanceMetres.isFinite ||
        distanceMetres < 0 ||
        segment < 0 ||
        (status == TrackingSessionStatus.completed && endedAt == null)) {
      throw const FormatException('Invalid tracking session');
    }
  }

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final TrackingSessionStatus status;
  final int elapsedMilliseconds;
  final double distanceMetres;
  final int segment;
  final List<TrackPoint> points;

  /// Updates the session without mutating route samples already in use by the UI.
  TrackingSession copyWith({
    TrackingSessionStatus? status,
    DateTime? endedAt,
    int? elapsedMilliseconds,
    double? distanceMetres,
    int? segment,
    List<TrackPoint>? points,
  }) => TrackingSession(
    id: id,
    startedAt: startedAt,
    status: status ?? this.status,
    endedAt: endedAt ?? this.endedAt,
    elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
    distanceMetres: distanceMetres ?? this.distanceMetres,
    segment: segment ?? this.segment,
    points: points ?? this.points,
  );
}
