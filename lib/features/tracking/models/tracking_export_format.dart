enum TrackingExportFormat {
  csv('csv', 'text/csv'),
  json('json', 'application/json');

  const TrackingExportFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}
