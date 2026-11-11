abstract final class RoutePaths {
  static const overview = '/';
  static const location = '/location';
  static const tracking = '/tracking';
  static const trackingHistory = '/tracking/history';

  /// Builds the route for a completed tracking session.
  static String trackingSession(String id) =>
      '/tracking/history/${Uri.encodeComponent(id)}';

  static const settings = '/settings';
}
