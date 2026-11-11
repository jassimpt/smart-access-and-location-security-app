abstract final class TrackingExportConstants {
  static const schemaVersion = 1;
  static const filePrefix = 'smart_access_tracking';
  static const cacheDirectory = 'tracking_exports';
  static const cacheRetention = Duration(days: 1);
  static const csvHeaders = [
    'session_id',
    'started_at_utc',
    'ended_at_utc',
    'duration_milliseconds',
    'distance_metres',
    'point_count',
    'point_index',
    'recorded_at_utc',
    'latitude',
    'longitude',
    'accuracy_metres',
    'speed_metres_per_second',
    'segment',
  ];
}
