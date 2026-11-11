import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../authentication/controllers/authentication_controller.dart';
import '../../authentication/states/authentication_state.dart';
import '../../location/services/location_service.dart';
import '../models/track_point.dart';
import '../models/tracking_session.dart';
import '../services/tracking_location_service.dart';
import '../services/tracking_metrics_service.dart';
import '../services/tracking_storage_service.dart';
import '../states/tracking_state.dart';

final trackingControllerProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);
final trackingClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class TrackingController extends Notifier<TrackingState> {
  StreamSubscription<TrackPoint>? _positions;
  StreamSubscription<bool>? _gpsStatus;
  Timer? _timer;
  DateTime? _activeSince;
  DateTime? _segmentSince;
  DateTime? _lastReading;
  int _baseElapsed = 0;
  int _generation = 0;
  int _ticks = 0;
  bool _foreground = true;
  bool _checkpointInFlight = false;
  bool _notificationsAllowed = false;
  Future<void> _writes = Future.value();
  Future<void> _cancellation = Future.value();
  Future<void>? _pauseTask;

  DateTime get _now => ref.read(trackingClockProvider)().toUtc();
  bool get _canTrack =>
      _foreground &&
      ref.read(authenticationControllerProvider).asData?.value.status ==
          AuthenticationStatus.unlocked;
  Duration get _elapsed => Duration(
    milliseconds:
        _baseElapsed +
        (_activeSince == null
            ? 0
            : max(0, _now.difference(_activeSince!).inMilliseconds)),
  );

  @override
  TrackingState build() {
    ref.onDispose(() {
      _timer?.cancel();
      unawaited(_positions?.cancel());
      unawaited(_gpsStatus?.cancel());
    });
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (next.asData?.value.status != AuthenticationStatus.unlocked) {
        ++_generation;
        unawaited(pause(message: TextConstants.trackingPausedBackground));
      }
    });
    return const TrackingState();
  }

  /// Restores completed history and recovers an interrupted session as paused.
  Future<void> initialize() async {
    if (state.initialized || state.isBusy) return;
    state = state.copyWith(isBusy: true, loadFailed: false, clearMessage: true);
    try {
      final storage = ref.read(trackingStorageServiceProvider);
      final active = await storage.loadActive();
      final history = await storage.loadHistory();
      if (!ref.mounted) return;
      final recovered = active?.copyWith(status: TrackingSessionStatus.paused);
      if (recovered != null) {
        await _enqueue(() => storage.saveActive(recovered));
      }
      if (!ref.mounted) return;
      _baseElapsed = recovered?.elapsedMilliseconds ?? 0;
      state = state.copyWith(
        session: recovered,
        history: history,
        initialized: true,
        elapsed: Duration(milliseconds: _baseElapsed),
        message: recovered == null ? null : TextConstants.trackingRecovered,
      );
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          loadFailed: true,
          message: TextConstants.trackingLoadFailed,
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Creates or resumes a session only after location access and persistence succeed.
  Future<void> startOrResume() async {
    if (!state.initialized || state.isBusy || state.isRunning || !_canTrack) {
      return;
    }
    state = state.copyWith(
      isBusy: true,
      clearMessage: true,
      clearAccessProblem: true,
    );
    final generation = ++_generation;
    try {
      await _pauseTask;
      await _cancellation;
      final device = await ref.read(locationServiceProvider).checkStatus();
      if (!ref.mounted || generation != _generation || !_canTrack) return;
      if (!device.canLocate) {
        state = state.copyWith(
          accessProblem: device,
          message: TextConstants.trackingLocationRequired,
        );
        return;
      }
      _notificationsAllowed = await ref
          .read(notificationServiceProvider)
          .requestPermission();
      if (!ref.mounted || generation != _generation || !_canTrack) return;
      state = state.copyWith(
        notificationWarning: _notificationsAllowed
            ? null
            : TextConstants.trackingNoNotification,
        clearNotificationWarning: _notificationsAllowed,
      );
      final resuming = state.session != null;
      final now = _now;
      final session =
          state.session?.copyWith(
            status: TrackingSessionStatus.paused,
            segment: state.session!.segment + 1,
          ) ??
          TrackingSession(
            id: '${now.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
            startedAt: now,
            status: TrackingSessionStatus.paused,
          );
      final storage = ref.read(trackingStorageServiceProvider);
      await _enqueue(() => storage.saveActive(session));
      if (!ref.mounted) return;
      state = state.copyWith(
        session: session,
        elapsed: Duration(milliseconds: session.elapsedMilliseconds),
        speed: 0,
        clearStorageWarning: true,
      );
      if (generation != _generation || !_canTrack) return;
      _baseElapsed = session.elapsedMilliseconds;
      _activeSince = _segmentSince = _now;
      _lastReading = null;
      _ticks = 0;
      state = state.copyWith(
        session: session.copyWith(status: TrackingSessionStatus.running),
        clearMessage: true,
      );
      _positions = ref
          .read(trackingLocationServiceProvider)
          .positions()
          .listen(
            _onPosition,
            onError: (Object error) {
              if (ref.mounted && state.isRunning) {
                unawaited(pause(message: TextConstants.trackingGpsLost));
              }
            },
            onDone: () {
              if (ref.mounted && state.isRunning) {
                unawaited(pause(message: TextConstants.trackingGpsLost));
              }
            },
          );
      _gpsStatus = ref
          .read(locationServiceProvider)
          .serviceChanges()
          .listen(
            (enabled) {
              if (ref.mounted && !enabled) {
                unawaited(pause(message: TextConstants.trackingGpsLost));
              }
            },
            onError: (Object error) {
              if (ref.mounted && state.isRunning) {
                unawaited(pause(message: TextConstants.trackingGpsLost));
              }
            },
          );
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      await _notify(
        resuming ? TrackingNotification.resumed : TrackingNotification.started,
      );
    } catch (_) {
      if (ref.mounted) {
        await pause(message: TextConstants.trackingStartFailed);
        state = state.copyWith(message: TextConstants.trackingStartFailed);
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Accepts quality GPS samples and updates route distance within the current segment.
  void _onPosition(TrackPoint raw) {
    if (!ref.mounted || !state.isRunning || !_canTrack) return;
    if (raw.recordedAt.isBefore(
          _segmentSince!.subtract(const Duration(seconds: 2)),
        ) ||
        raw.recordedAt.isAfter(_now.add(const Duration(minutes: 1)))) {
      return;
    }
    final session = state.session!;
    if (session.points.isNotEmpty &&
        !raw.recordedAt.isAfter(session.points.last.recordedAt)) {
      return;
    }
    final point = raw.inSegment(session.segment);
    final result = ref
        .read(trackingMetricsServiceProvider)
        .evaluate(session.points.lastOrNull, point);
    _lastReading = _now;
    if (!result.accepted) {
      state = state.copyWith(
        speed: 0,
        message: point.accuracy > 75 ? TextConstants.trackingWeakSignal : null,
        clearMessage: point.accuracy <= 75,
      );
      return;
    }
    state = state.copyWith(
      session: session.copyWith(
        points: [...session.points, point],
        distanceMetres: session.distanceMetres + result.distance,
        elapsedMilliseconds: _elapsed.inMilliseconds,
      ),
      elapsed: _elapsed,
      speed: result.speed,
      clearMessage: true,
    );
    if (session.points.isEmpty) unawaited(_checkpoint());
  }

  /// Updates active duration and writes bounded periodic checkpoints.
  void _tick() {
    if (!ref.mounted || !state.isRunning) return;
    final speed =
        _lastReading == null ||
            _now.difference(_lastReading!) > const Duration(seconds: 10)
        ? 0.0
        : state.speed;
    state = state.copyWith(elapsed: _elapsed, speed: speed);
    if (++_ticks % 5 == 0) unawaited(_checkpoint());
  }

  /// Saves progress without allowing a late checkpoint to overwrite a pause or stop.
  Future<void> _checkpoint() async {
    if (_checkpointInFlight || !state.isRunning) return;
    _checkpointInFlight = true;
    final session = state.session!.copyWith(
      elapsedMilliseconds: _elapsed.inMilliseconds,
    );
    try {
      final storage = ref.read(trackingStorageServiceProvider);
      await _enqueue(() => storage.saveActive(session));
      if (ref.mounted) state = state.copyWith(clearStorageWarning: true);
    } catch (_) {
      if (ref.mounted) {
        await pause(message: TextConstants.trackingSaveFailed, save: false);
        state = state.copyWith(
          storageWarning: TextConstants.trackingSaveFailed,
        );
      }
    } finally {
      _checkpointInFlight = false;
    }
  }

  /// Pauses immediately, stops all listeners, and saves a recoverable session.
  Future<void> pause({String? message, bool save = true, bool notify = true}) {
    if (_pauseTask != null) return _pauseTask!;
    if (!state.isRunning) return Future.value();
    final task = _pauseRecording(message: message, save: save, notify: notify);
    _pauseTask = task;
    return task.whenComplete(() => _pauseTask = null);
  }

  /// Completes one pause before a resume or stop can alter its persisted record.
  Future<void> _pauseRecording({
    String? message,
    required bool save,
    required bool notify,
  }) async {
    if (!state.isRunning) return;
    final paused = state.session!.copyWith(
      status: TrackingSessionStatus.paused,
      elapsedMilliseconds: _elapsed.inMilliseconds,
    );
    _baseElapsed = paused.elapsedMilliseconds;
    _activeSince = null;
    state = state.copyWith(
      session: paused,
      elapsed: Duration(milliseconds: _baseElapsed),
      speed: 0,
      message: message ?? TextConstants.trackingPausedManually,
    );
    try {
      await _cancelRecording();
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(message: TextConstants.trackingCancelFailed);
      }
    }
    if (save) {
      try {
        final storage = ref.read(trackingStorageServiceProvider);
        await _enqueue(() => storage.saveActive(paused));
        if (ref.mounted) state = state.copyWith(clearStorageWarning: true);
      } catch (_) {
        if (ref.mounted) {
          state = state.copyWith(
            storageWarning: TextConstants.trackingSaveFailed,
          );
        }
      }
    }
    if (ref.mounted && notify) await _notify(TrackingNotification.paused);
  }

  /// Completes the session only after the archive write succeeds.
  Future<void> stopAndSave() async {
    if (state.session == null || state.isBusy) return;
    state = state.copyWith(isBusy: true, clearMessage: true);
    try {
      if (state.isRunning) {
        await pause(notify: false);
      } else {
        await _pauseTask;
      }
      if (!ref.mounted) return;
      final completed = state.session!.copyWith(
        status: TrackingSessionStatus.completed,
        endedAt: _now,
      );
      final storage = ref.read(trackingStorageServiceProvider);
      await _enqueue(() => storage.complete(completed));
      if (!ref.mounted) return;
      final history = [
        completed,
        ...state.history.where((session) => session.id != completed.id),
      ]..sort((first, second) => second.startedAt.compareTo(first.startedAt));
      state = state.copyWith(
        clearSession: true,
        history: history,
        elapsed: Duration.zero,
        speed: 0,
        message: TextConstants.trackingSessionSaved,
        clearStorageWarning: true,
      );
      await _notify(TrackingNotification.stopped);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          storageWarning: TextConstants.trackingSaveFailed,
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Removes completed sessions after the UI has obtained user confirmation.
  Future<void> clearHistory() async {
    if (!state.initialized || state.isBusy) return;
    state = state.copyWith(isBusy: true, clearMessage: true);
    try {
      final storage = ref.read(trackingStorageServiceProvider);
      await _enqueue(storage.clearHistory);
      if (ref.mounted) {
        state = state.copyWith(
          history: const [],
          message: TextConstants.trackingHistoryCleared,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          message: TextConstants.trackingHistoryClearFailed,
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Serializes local writes so old GPS checkpoints cannot replace newer records.
  Future<void> _enqueue(Future<void> Function() write) {
    final next = _writes.then((_) => write());
    _writes = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  /// Posts notifications without preventing tracking when permission or delivery fails.
  Future<void> _notify(TrackingNotification notification) async {
    if (!_notificationsAllowed) return;
    try {
      await ref
          .read(notificationServiceProvider)
          .showTrackingUpdate(notification);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          notificationWarning: TextConstants.trackingNoNotification,
        );
      }
    }
  }

  /// Cancels the timer and both native listeners exactly once.
  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _timer = null;
    final positions = _positions;
    final gps = _gpsStatus;
    _positions = null;
    _gpsStatus = null;
    _cancellation = Future.wait<void>([
      if (positions != null) positions.cancel(),
      if (gps != null) gps.cancel(),
    ]).then((_) {});
    await _cancellation;
  }

  /// Pauses foreground-only recording when minimized and requires explicit resume.
  void handleLifecycle(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      _foreground = false;
      ++_generation;
      unawaited(pause(message: TextConstants.trackingPausedBackground));
    } else if (lifecycle == AppLifecycleState.resumed) {
      _foreground = true;
    }
  }
}
