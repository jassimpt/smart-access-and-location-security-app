import '../../../core/constants/text_constants.dart';
import '../models/geofence.dart';

abstract final class GeofenceValidators {
  /// Validates the user-visible area name.
  static String? name(String? input) {
    final value = input?.trim() ?? '';
    return value.isEmpty || value.length > Geofence.maxNameLength
        ? TextConstants.geofenceNameInvalid
        : null;
  }

  /// Validates a latitude without accepting non-finite numeric values.
  static String? latitude(String? input) {
    final value = double.tryParse(input?.trim() ?? '');
    return value == null || !value.isFinite || value.abs() > 90
        ? TextConstants.latitudeInvalid
        : null;
  }

  /// Validates a longitude without accepting non-finite numeric values.
  static String? longitude(String? input) {
    final value = double.tryParse(input?.trim() ?? '');
    return value == null || !value.isFinite || value.abs() > 180
        ? TextConstants.longitudeInvalid
        : null;
  }

  /// Validates the supported boundary radius in metres.
  static String? radius(String? input) {
    final value = double.tryParse(input?.trim() ?? '');
    return value == null ||
            !value.isFinite ||
            value < Geofence.minRadius ||
            value > Geofence.maxRadius
        ? TextConstants.radiusInvalid
        : null;
  }
}
