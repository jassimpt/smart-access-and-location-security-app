class Geofence {
  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        name.length > maxNameLength ||
        !latitude.isFinite ||
        latitude.abs() > 90 ||
        !longitude.isFinite ||
        longitude.abs() > 180 ||
        !radiusMetres.isFinite ||
        radiusMetres < minRadius ||
        radiusMetres > maxRadius) {
      throw const FormatException('Invalid geofence');
    }
  }
  static const minRadius = 50.0;
  static const maxRadius = 10000.0;
  static const maxNameLength = 60;

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMetres;
  final DateTime createdAt;
  final DateTime updatedAt;
}
