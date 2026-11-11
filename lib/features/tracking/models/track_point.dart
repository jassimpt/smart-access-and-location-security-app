class TrackPoint {
  TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    this.speed = 0,
    this.segment = 0,
  }) {
    if (!latitude.isFinite ||
        latitude.abs() > 90 ||
        !longitude.isFinite ||
        longitude.abs() > 180 ||
        !accuracy.isFinite ||
        accuracy < 0 ||
        !speed.isFinite ||
        speed < 0 ||
        segment < 0) {
      throw const FormatException('Invalid tracking point');
    }
  }
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime recordedAt;
  final double speed;
  final int segment;

  /// Assigns a GPS reading to the current continuous route segment.
  TrackPoint inSegment(int segment) => TrackPoint(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    recordedAt: recordedAt,
    speed: speed,
    segment: segment,
  );
}
