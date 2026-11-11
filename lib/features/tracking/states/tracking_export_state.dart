class TrackingExportState {
  const TrackingExportState({
    this.isExporting = false,
    this.message,
    this.isError = false,
  });

  final bool isExporting;
  final String? message;
  final bool isError;
}
