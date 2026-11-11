import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../authentication/controllers/authentication_controller.dart';
import '../../authentication/states/authentication_state.dart';
import '../models/location_device_status.dart';
import '../models/location_snapshot.dart';
import '../services/address_service.dart';
import '../services/location_service.dart';
import '../services/location_storage_service.dart';
import '../states/location_state.dart';

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

class LocationController extends Notifier<LocationState> {
  StreamSubscription<bool>? _serviceSubscription;
  bool _started = false;
  bool _foreground = true;
  bool _cacheLoaded = false;
  bool _inFlight = false;
  bool _queuedRefresh = false;
  int _generation = 0;

  @override
  LocationState build() {
    ref.onDispose(() {
      ++_generation;
      unawaited(_serviceSubscription?.cancel());
    });
    ref.listen(authenticationControllerProvider, (previous, next) {
      final status = next.asData?.value.status;
      if (status != AuthenticationStatus.unlocked) {
        _suspend();
      } else if (previous?.asData?.value.status !=
              AuthenticationStatus.unlocked &&
          _started &&
          _foreground) {
        unawaited(refresh(queueIfBusy: !state.isBusy));
      }
    });
    return const LocationState();
  }

  bool get _canLocate =>
      _foreground &&
      ref.read(authenticationControllerProvider).asData?.value.status ==
          AuthenticationStatus.unlocked;

  /// Loads saved data and refreshes GPS only when permission is already granted.
  Future<void> initialize() => refresh();

  /// Requests location permission only after the user accepts the explanation.
  Future<void> requestAccess() => refresh(requestPermission: true);

  /// Gets one location reading, keeping saved coordinates usable on failure.
  Future<void> refresh({
    bool requestPermission = false,
    bool queueIfBusy = false,
  }) async {
    if (!_canLocate) return;
    _started = true;
    if (_inFlight) {
      _queuedRefresh |= queueIfBusy;
      return;
    }
    _inFlight = true;
    final generation = ++_generation;
    state = state.copyWith(
      isBusy: true,
      isCached: state.snapshot != null,
      clearMessage: true,
    );
    try {
      if (!_cacheLoaded) {
        await _loadCache(generation);
        if (!_isCurrent(generation)) return;
      }
      _watchService();
      final service = ref.read(locationServiceProvider);
      var device = await service.checkStatus();
      if (!_isCurrent(generation)) return;
      if (requestPermission &&
          device.serviceEnabled &&
          device.permission != LocationPermissionStatus.granted) {
        final permission = await service.requestPermission();
        if (!_isCurrent(generation)) return;
        device = LocationDeviceStatus(
          serviceEnabled: await service.checkStatus().then(
            (value) => value.serviceEnabled,
          ),
          permission: permission,
        );
      } else if (device.permission == LocationPermissionStatus.denied &&
          state.device?.permission ==
              LocationPermissionStatus.permanentlyDenied) {
        device = LocationDeviceStatus(
          serviceEnabled: device.serviceEnabled,
          permission: LocationPermissionStatus.permanentlyDenied,
        );
      }
      if (!_isCurrent(generation)) return;
      state = state.copyWith(device: device, status: _statusFor(device));
      if (!device.canLocate) return;
      final previous = state.snapshot;
      var snapshot = await service.currentPosition();
      if (!_isCurrent(generation)) return;
      final nearbyAddress =
          previous?.address != null &&
          service.distanceBetween(previous!, snapshot) <= 25;
      if (nearbyAddress) snapshot = snapshot.withAddress(previous.address!);
      state = state.copyWith(
        snapshot: snapshot,
        isCached: false,
        isAddressCached: nearbyAddress,
        isResolvingAddress: !nearbyAddress,
        status: LocationStatus.ready,
        clearMessage: true,
      );
      await _save(snapshot, generation);
      if (!_isCurrent(generation) || nearbyAddress) return;
      final address = await ref.read(addressServiceProvider).resolve(snapshot);
      if (!_isCurrent(generation)) return;
      if (address != null && address.trim().isNotEmpty) {
        snapshot = snapshot.withAddress(address);
        state = state.copyWith(snapshot: snapshot);
        await _save(snapshot, generation);
      }
    } on TimeoutException {
      if (_isCurrent(generation)) {
        state = state.copyWith(
          message: TextConstants.locationTimeout,
          isCached: state.snapshot != null,
          status: LocationStatus.unavailable,
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        try {
          final device = await ref.read(locationServiceProvider).checkStatus();
          if (_isCurrent(generation)) {
            state = state.copyWith(
              device: device,
              status: device.canLocate
                  ? LocationStatus.unavailable
                  : _statusFor(device),
              message: device.canLocate
                  ? TextConstants.locationRefreshFailed
                  : null,
            );
          }
        } catch (_) {
          if (_isCurrent(generation)) {
            state = state.copyWith(
              status: LocationStatus.unavailable,
              message: TextConstants.locationRefreshFailed,
            );
          }
        }
      }
    } finally {
      _inFlight = false;
      if (ref.mounted) {
        if (generation == _generation) {
          state = state.copyWith(isBusy: false, isResolvingAddress: false);
        }
        if (_queuedRefresh && _canLocate) {
          _queuedRefresh = false;
          unawaited(refresh());
        }
      }
    }
  }

  /// Restores the last known position without preventing fresh GPS on cache errors.
  Future<void> _loadCache(int generation) async {
    try {
      final snapshot = await ref
          .read(locationStorageServiceProvider)
          .loadLatest();
      if (_isCurrent(generation) && snapshot != null) {
        state = state.copyWith(
          snapshot: snapshot,
          isCached: true,
          isAddressCached: snapshot.address != null,
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        state = state.copyWith(
          storageWarning: TextConstants.locationCacheLoadFailed,
        );
      }
    }
    if (_isCurrent(generation)) _cacheLoaded = true;
  }

  /// Persists a reading while keeping the live result usable on storage failure.
  Future<void> _save(LocationSnapshot snapshot, int generation) async {
    try {
      await ref.read(locationStorageServiceProvider).saveLatest(snapshot);
      if (_isCurrent(generation)) {
        state = state.copyWith(clearStorageWarning: true);
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        state = state.copyWith(
          storageWarning: TextConstants.locationSaveFailed,
        );
      }
    }
  }

  /// Maintains one GPS-status listener while the app is unlocked and foregrounded.
  void _watchService() {
    _serviceSubscription ??= ref
        .read(locationServiceProvider)
        .serviceChanges()
        .listen(
          (enabled) {
            if (!ref.mounted || !_canLocate) return;
            if (!enabled) {
              ++_generation;
              state = state.copyWith(
                device: LocationDeviceStatus(
                  serviceEnabled: false,
                  permission:
                      state.device?.permission ??
                      LocationPermissionStatus.denied,
                ),
                status: LocationStatus.gpsDisabled,
                isBusy: false,
                isResolvingAddress: false,
                isCached: state.snapshot != null,
              );
            } else {
              unawaited(refresh(queueIfBusy: !state.isBusy));
            }
          },
          onError: (Object error) {
            if (ref.mounted && _canLocate) {
              state = state.copyWith(
                message: TextConstants.locationServiceMonitorFailed,
              );
            }
          },
        );
  }

  /// Stops monitoring and invalidates results when the app is locked or backgrounded.
  void _suspend() {
    ++_generation;
    _queuedRefresh = false;
    unawaited(_serviceSubscription?.cancel());
    _serviceSubscription = null;
    state = state.copyWith(
      isBusy: false,
      isResolvingAddress: false,
      isCached: state.snapshot != null,
    );
  }

  /// Rechecks GPS and permissions after returning from device settings.
  void handleLifecycle(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      _foreground = false;
      _suspend();
    } else if (lifecycle == AppLifecycleState.resumed) {
      _foreground = true;
      if (_started) unawaited(refresh(queueIfBusy: !state.isBusy));
    }
  }

  /// Opens the app permission settings and reports an unavailable settings link.
  Future<void> openAppSettings() =>
      _openSettings(ref.read(locationServiceProvider).openAppSettings);

  /// Opens location services settings without changing permissions automatically.
  Future<void> openLocationSettings() =>
      _openSettings(ref.read(locationServiceProvider).openLocationSettings);

  /// Handles platform settings failures as recoverable UI messages.
  Future<void> _openSettings(Future<bool> Function() open) async {
    try {
      if (!await open() && ref.mounted) {
        state = state.copyWith(
          message: TextConstants.locationSettingsUnavailable,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          message: TextConstants.locationSettingsUnavailable,
        );
      }
    }
  }

  /// Rejects stale results from a previous refresh or a backgrounded app.
  bool _isCurrent(int generation) =>
      ref.mounted && generation == _generation && _canLocate;

  /// Converts the device status into the appropriate recovery screen.
  LocationStatus _statusFor(LocationDeviceStatus device) {
    if (!device.serviceEnabled) return LocationStatus.gpsDisabled;
    return switch (device.permission) {
      LocationPermissionStatus.granted => LocationStatus.ready,
      LocationPermissionStatus.permanentlyDenied =>
        LocationStatus.permanentlyDenied,
      LocationPermissionStatus.denied => LocationStatus.permissionRequired,
    };
  }
}
