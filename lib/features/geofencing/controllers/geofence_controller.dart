import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../authentication/controllers/authentication_controller.dart';
import '../../authentication/states/authentication_state.dart';
import '../../location/models/location_snapshot.dart';
import '../../location/services/location_service.dart';
import '../models/geofence.dart';
import '../models/geofence_event.dart';
import '../services/geofence_boundary_service.dart';
import '../services/geofence_location_service.dart';
import '../services/geofence_storage_service.dart';
import '../states/geofence_state.dart';

final geofenceControllerProvider =
    NotifierProvider<GeofenceController, GeofenceState>(GeofenceController.new);
final geofenceClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class GeofenceController extends Notifier<GeofenceState> {
  StreamSubscription<LocationSnapshot>? _positions;
  StreamSubscription<bool>? _gpsStatus;
  Future<void> _cancellation = Future.value();
  bool _foreground = true;
  bool _notificationsAllowed = false;
  DateTime? _startedAt;
  DateTime? _lastFixAt;
  int _generation = 0;

  DateTime get _now => ref.read(geofenceClockProvider)().toUtc();
  bool get _canMonitor =>
      _foreground &&
      ref.read(authenticationControllerProvider).asData?.value.status ==
          AuthenticationStatus.unlocked;

  @override
  GeofenceState build() {
    ref.onDispose(() {
      unawaited(_positions?.cancel());
      unawaited(_gpsStatus?.cancel());
    });
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (next.asData?.value.status != AuthenticationStatus.unlocked) {
        unawaited(stopMonitoring(message: TextConstants.monitoringPaused));
      }
    });
    return GeofenceState();
  }

  /// Loads saved boundaries without starting GPS monitoring automatically.
  Future<void> initialize() async {
    if (state.initialized || state.isBusy) return;
    state = state.copyWith(isBusy: true, loadFailed: false, clearMessage: true);
    try {
      final fences = await ref.read(geofenceStorageServiceProvider).load();
      if (ref.mounted) {
        state = state.copyWith(fences: fences, initialized: true);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          loadFailed: true,
          message: TextConstants.geofenceLoadFailed,
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Saves one validated boundary and resets its baseline after an edit.
  Future<bool> saveGeofence({
    Geofence? existing,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    if (!state.initialized || state.isBusy) return false;
    if (existing != null &&
        !state.fences.any((fence) => fence.id == existing.id)) {
      state = state.copyWith(message: TextConstants.geofenceNotFound);
      return false;
    }
    state = state.copyWith(isBusy: true, clearMessage: true);
    try {
      final now = _now;
      final fence = Geofence(
        id:
            existing?.id ??
            '${now.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
        name: name.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusMetres: radius,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(geofenceStorageServiceProvider).save(fence);
      if (!ref.mounted) return false;
      final fences = [
        fence,
        ...state.fences.where((saved) => saved.id != fence.id),
      ];
      final presences = Map<String, GeofencePresence>.from(state.presences)
        ..remove(fence.id);
      final events = Map<String, GeofenceEvent>.from(state.events)
        ..remove(fence.id);
      state = state.copyWith(
        fences: fences,
        presences: presences,
        events: events,
        message: TextConstants.geofenceSaved,
      );
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(message: TextConstants.geofenceSaveFailed);
      }
      return false;
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Deletes only the confirmed boundary and stops monitoring if no areas remain.
  Future<void> deleteGeofence(String id) async {
    if (!state.initialized || state.isBusy) return;
    state = state.copyWith(isBusy: true, clearMessage: true);
    try {
      await ref.read(geofenceStorageServiceProvider).delete(id);
      if (!ref.mounted) return;
      final fences = state.fences.where((fence) => fence.id != id).toList();
      final presences = Map<String, GeofencePresence>.from(state.presences)
        ..remove(id);
      final events = Map<String, GeofenceEvent>.from(state.events)..remove(id);
      state = state.copyWith(
        fences: fences,
        presences: presences,
        events: events,
        message: TextConstants.geofenceDeleted,
      );
      if (fences.isEmpty) await stopMonitoring();
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(message: TextConstants.geofenceDeleteFailed);
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Starts one foreground listener after checking location and notification access.
  Future<void> startMonitoring() async {
    if (!state.initialized ||
        state.isBusy ||
        state.isMonitoring ||
        state.fences.isEmpty ||
        !_canMonitor) {
      return;
    }
    state = state.copyWith(isBusy: true, clearMessage: true);
    final generation = ++_generation;
    try {
      await _cancellation;
      final device = await ref.read(locationServiceProvider).checkStatus();
      if (!ref.mounted || generation != _generation || !_canMonitor) return;
      if (!device.canLocate) {
        state = state.copyWith(
          message: TextConstants.monitoringLocationRequired,
        );
        return;
      }
      _notificationsAllowed = await ref
          .read(notificationServiceProvider)
          .requestPermission();
      if (!ref.mounted || generation != _generation || !_canMonitor) return;
      _startedAt = _now;
      _lastFixAt = null;
      state = state.copyWith(
        isMonitoring: true,
        presences: const {},
        events: const {},
        clearPosition: true,
        notificationWarning: _notificationsAllowed
            ? null
            : TextConstants.geofenceNotificationUnavailable,
        clearNotificationWarning: _notificationsAllowed,
      );
      _positions = ref
          .read(geofenceLocationServiceProvider)
          .positions()
          .listen(
            _onPosition,
            onError: (Object error) {
              if (ref.mounted) {
                unawaited(
                  stopMonitoring(message: TextConstants.monitoringGpsLost),
                );
              }
            },
            onDone: () {
              if (ref.mounted && state.isMonitoring) {
                unawaited(
                  stopMonitoring(message: TextConstants.monitoringGpsLost),
                );
              }
            },
          );
      _gpsStatus = ref
          .read(locationServiceProvider)
          .serviceChanges()
          .listen(
            (enabled) {
              if (ref.mounted && !enabled) {
                unawaited(
                  stopMonitoring(message: TextConstants.monitoringGpsLost),
                );
              }
            },
            onError: (Object error) {
              if (ref.mounted) {
                unawaited(
                  stopMonitoring(message: TextConstants.monitoringGpsLost),
                );
              }
            },
          );
    } catch (_) {
      if (ref.mounted) {
        await stopMonitoring(message: TextConstants.monitoringStartFailed);
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Establishes baselines and emits only confident changes from an existing baseline.
  void _onPosition(LocationSnapshot position) {
    if (!ref.mounted || !state.isMonitoring || !_canMonitor) return;
    if (position.recordedAt.isBefore(
          _startedAt!.subtract(const Duration(seconds: 2)),
        ) ||
        position.recordedAt.isAfter(_now.add(const Duration(minutes: 1))) ||
        (_lastFixAt != null && !position.recordedAt.isAfter(_lastFixAt!))) {
      return;
    }
    _lastFixAt = position.recordedAt;
    final presences = Map<String, GeofencePresence>.from(state.presences);
    final events = Map<String, GeofenceEvent>.from(state.events);
    final transitions = <(Geofence, bool)>[];
    final evaluator = ref.read(geofenceBoundaryServiceProvider);
    for (final fence in state.fences) {
      final previous = presences[fence.id] ?? GeofencePresence.unknown;
      final current = evaluator.evaluate(fence, position, previous);
      presences[fence.id] = current;
      if (previous != GeofencePresence.unknown && current != previous) {
        final entered = current == GeofencePresence.inside;
        events[fence.id] = GeofenceEvent(
          transition: entered
              ? GeofenceTransition.entered
              : GeofenceTransition.exited,
          occurredAt: position.recordedAt,
        );
        transitions.add((fence, entered));
      }
    }
    final imprecise = state.fences.any(
      (fence) =>
          position.accuracy <= 0 ||
          position.accuracy > min(75, fence.radiusMetres / 2),
    );
    state = state.copyWith(
      presences: presences,
      events: events,
      lastPosition: position,
      message: imprecise ? TextConstants.geofenceWeakGps : null,
      clearMessage: !imprecise,
    );
    for (final (fence, entered) in transitions) {
      unawaited(_notify(fence, entered));
    }
  }

  /// Delivers a local alert without stopping monitoring if notification delivery fails.
  Future<void> _notify(Geofence fence, bool entered) async {
    if (!_notificationsAllowed) return;
    try {
      await ref
          .read(notificationServiceProvider)
          .showGeofenceTransition(
            geofenceId: fence.id,
            name: fence.name,
            entered: entered,
          );
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          notificationWarning: TextConstants.geofenceNotificationUnavailable,
        );
      }
    }
  }

  /// Cancels monitoring once and clears baselines so missed background movement is not inferred.
  Future<void> stopMonitoring({String? message}) async {
    ++_generation;
    final wasMonitoring = state.isMonitoring;
    state = state.copyWith(
      isMonitoring: false,
      presences: const {},
      message: wasMonitoring ? message : null,
    );
    final positions = _positions;
    final gps = _gpsStatus;
    _positions = null;
    _gpsStatus = null;
    if (positions == null && gps == null) return;
    _cancellation =
        Future.wait<void>([
          if (positions != null) positions.cancel(),
          if (gps != null) gps.cancel(),
        ]).then<void>(
          (_) {},
          onError: (Object error, StackTrace stack) {
            if (ref.mounted) {
              state = state.copyWith(
                message: TextConstants.monitoringCancelFailed,
              );
            }
          },
        );
    await _cancellation;
  }

  /// Stops monitoring when locked or minimized without restarting it automatically.
  void handleLifecycle(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      _foreground = false;
      unawaited(stopMonitoring(message: TextConstants.monitoringPaused));
    } else if (lifecycle == AppLifecycleState.resumed) {
      _foreground = true;
    }
  }
}
