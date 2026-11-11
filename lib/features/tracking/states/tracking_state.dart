import '../../location/models/location_device_status.dart';
import '../models/tracking_session.dart';

class TrackingState {
  const TrackingState({
    this.session,
    this.history = const [],
    this.initialized = false,
    this.isBusy = false,
    this.loadFailed = false,
    this.elapsed = Duration.zero,
    this.speed = 0,
    this.message,
    this.notificationWarning,
    this.storageWarning,
    this.accessProblem,
  });

  final TrackingSession? session;
  final List<TrackingSession> history;
  final bool initialized;
  final bool isBusy;
  final bool loadFailed;
  final Duration elapsed;
  final double speed;
  final String? message;
  final String? notificationWarning;
  final String? storageWarning;
  final LocationDeviceStatus? accessProblem;
  bool get isRunning => session?.status == TrackingSessionStatus.running;

  /// Updates tracking UI state while retaining immutable session and history data.
  TrackingState copyWith({
    TrackingSession? session,
    bool clearSession = false,
    List<TrackingSession>? history,
    bool? initialized,
    bool? isBusy,
    bool? loadFailed,
    Duration? elapsed,
    double? speed,
    String? message,
    bool clearMessage = false,
    String? notificationWarning,
    bool clearNotificationWarning = false,
    String? storageWarning,
    bool clearStorageWarning = false,
    LocationDeviceStatus? accessProblem,
    bool clearAccessProblem = false,
  }) => TrackingState(
    session: clearSession ? null : session ?? this.session,
    history: history ?? this.history,
    initialized: initialized ?? this.initialized,
    isBusy: isBusy ?? this.isBusy,
    loadFailed: loadFailed ?? this.loadFailed,
    elapsed: elapsed ?? this.elapsed,
    speed: speed ?? this.speed,
    message: clearMessage ? null : message ?? this.message,
    notificationWarning: clearNotificationWarning
        ? null
        : notificationWarning ?? this.notificationWarning,
    storageWarning: clearStorageWarning
        ? null
        : storageWarning ?? this.storageWarning,
    accessProblem: clearAccessProblem
        ? null
        : accessProblem ?? this.accessProblem,
  );
}
