import 'package:latlong2/latlong.dart';

class MapBoundary {
  const MapBoundary({
    required this.center,
    required this.radius,
    required this.label,
  });
  final LatLng center;
  final double radius;
  final String label;
}
