abstract final class RoutePaths {
  static const overview = '/';
  static const location = '/location';
  static const tracking = '/tracking';
  static const trackingHistory = '/tracking/history';

  /// Builds the route for a completed tracking session.
  static String trackingSession(String id) =>
      '/tracking/history/${Uri.encodeComponent(id)}';

  static const geofences = '/geofences';
  static const geofenceNew = '/geofences/new';

  /// Builds the route for a saved geofence.
  static String geofenceDetail(String id) =>
      '/geofences/${Uri.encodeComponent(id)}';

  /// Builds the edit route for a saved geofence.
  static String geofenceEdit(String id) =>
      '/geofences/${Uri.encodeComponent(id)}/edit';

  static const settings = '/settings';
}
