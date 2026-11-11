class LocationSnapshot {
  LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    this.isApproximate,
    this.address,
  }) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        !accuracy.isFinite ||
        accuracy < 0) {
      throw const FormatException('Invalid location snapshot');
    }
  }

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime recordedAt;
  final bool? isApproximate;
  final String? address;

  /// Associates an address only with this position.
  LocationSnapshot withAddress(String address) => LocationSnapshot(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    recordedAt: recordedAt,
    isApproximate: isApproximate,
    address: address,
  );
}
