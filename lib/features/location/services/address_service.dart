import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../models/location_snapshot.dart';

final addressServiceProvider = Provider((ref) => AddressService());

class AddressService {
  Geocoding? _geocoding;

  /// Resolves an address through the device geocoder without blocking GPS on failure.
  Future<String?> resolve(LocationSnapshot location) async {
    try {
      final placemarks = await (_geocoding ??= Geocoding())
          .placemarkFromCoordinates(location.latitude, location.longitude)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isEmpty) return null;
      return formatPlacemark(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  /// Formats available address components without duplicates or empty separators.
  String? formatPlacemark(Placemark placemark) {
    final parts = <String>[];
    final seen = <String>{};
    for (final component in [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ]) {
      final value = component?.trim();
      if (value != null && value.isNotEmpty && seen.add(value.toLowerCase())) {
        parts.add(value);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }
}
