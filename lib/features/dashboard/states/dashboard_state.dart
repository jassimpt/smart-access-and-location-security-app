class DashboardState {
  const DashboardState({
    this.isRefreshing = false,
    this.checkedAt,
    this.message,
  });
  final bool isRefreshing;
  final DateTime? checkedAt;
  final String? message;
}
