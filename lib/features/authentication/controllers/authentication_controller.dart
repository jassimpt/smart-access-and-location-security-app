import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../models/authentication_record.dart';
import '../models/auto_lock_duration.dart';
import '../models/biometric_capabilities.dart';
import '../services/authentication_service.dart';
import '../services/biometric_service.dart';
import '../services/pin_service.dart';
import '../states/authentication_state.dart';

final authenticationControllerProvider =
    AsyncNotifierProvider<AuthenticationController, AuthenticationState>(
      AuthenticationController.new,
      retry: (retryCount, error) => null,
    );
final authenticationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class AuthenticationController extends AsyncNotifier<AuthenticationState> {
  Timer? _idleTimer;
  Timer? _lockoutTimer;
  DateTime? _backgroundAt;
  bool _foreground = true;
  int _operation = 0;
  bool _refreshing = false;

  DateTime get _now => ref.read(authenticationClockProvider)().toUtc();
  AuthenticationState get _current => state.requireValue;

  @override
  Future<AuthenticationState> build() async {
    final biometrics = ref.read(biometricServiceProvider);
    ref.onDispose(() {
      _idleTimer?.cancel();
      _lockoutTimer?.cancel();
      unawaited(biometrics.cancel());
    });
    final record = await ref.read(authenticationServiceProvider).load();
    final capabilities = await ref
        .read(biometricServiceProvider)
        .capabilities();
    _scheduleLockoutExpiry(record);
    return AuthenticationState(
      status: record == null
          ? AuthenticationStatus.setupRequired
          : AuthenticationStatus.locked,
      record: record,
      capabilities: capabilities,
      isObscured: !_foreground,
    );
  }

  /// Creates the PIN and unlocks only after secure persistence succeeds.
  Future<void> createPin(String pin, String confirmation) async {
    if (_current.isBusy ||
        _current.status != AuthenticationStatus.setupRequired) {
      return;
    }
    final pins = ref.read(pinServiceProvider);
    if (!pins.isValid(pin) || pin != confirmation) {
      _update(
        _current.copyWith(
          message: pin != confirmation
              ? TextConstants.pinMismatch
              : TextConstants.invalidPin,
        ),
      );
      return;
    }
    final operation = _beginOperation();
    try {
      final credential = await pins.create(pin);
      if (!ref.mounted) return;
      await _commit(
        AuthenticationRecord(credential: credential, lastAuthenticatedAt: _now),
        AuthenticationStatus.unlocked,
        operation,
      );
    } catch (_) {
      _storageError();
    } finally {
      _endOperation();
    }
  }

  /// Verifies the PIN and persists failed attempts before accepting another try.
  Future<void> unlockWithPin(String pin) async {
    if (_current.isBusy || _current.status != AuthenticationStatus.locked) {
      return;
    }
    final record = _current.record!;
    if (isPinLockedOut) {
      _update(_current.copyWith(message: TextConstants.pinLockout));
      return;
    }
    if (!ref.read(pinServiceProvider).isValid(pin)) {
      _update(_current.copyWith(message: TextConstants.invalidPin));
      return;
    }
    final operation = _beginOperation();
    try {
      final valid = await ref
          .read(pinServiceProvider)
          .verify(pin, record.credential);
      if (!ref.mounted) return;
      if (valid) {
        if (_backgroundAt != null || operation != _operation) return;
        await _commit(
          record.copyWith(
            failedAttempts: 0,
            clearLockout: true,
            lastAuthenticatedAt: _now,
          ),
          AuthenticationStatus.unlocked,
          operation,
        );
      } else {
        final attempts =
            (record.lockedUntil != null ? 0 : record.failedAttempts) + 1;
        final updated = record.copyWith(
          failedAttempts: attempts,
          lockedUntil: attempts >= 5
              ? _now.add(const Duration(seconds: 30))
              : null,
          clearLockout: attempts < 5,
        );
        await _commit(updated, AuthenticationStatus.locked, operation);
        if (ref.mounted) {
          _scheduleLockoutExpiry(updated);
          _update(
            _current.copyWith(
              message: attempts >= 5
                  ? TextConstants.pinLockout
                  : TextConstants.incorrectPin,
            ),
          );
        }
      }
    } catch (_) {
      _storageError();
    } finally {
      _endOperation();
    }
  }

  bool get isPinLockedOut =>
      _current.record?.lockedUntil?.isAfter(_now) ?? false;

  /// Unlocks with enrolled biometrics when the user has enabled this option.
  Future<void> unlockWithBiometrics() async {
    if (_current.isBusy ||
        _current.status != AuthenticationStatus.locked ||
        !(_current.record?.biometricsEnabled ?? false)) {
      return;
    }
    await _authenticateBiometrics(enable: false);
  }

  /// Verifies biometrics before enabling them, or saves the disabled preference.
  Future<void> setBiometricsEnabled(bool enabled) async {
    if (_current.isBusy || _current.status != AuthenticationStatus.unlocked) {
      return;
    }
    if (enabled) {
      await _authenticateBiometrics(enable: true);
    } else {
      await _savePreferences(
        _current.record!.copyWith(biometricsEnabled: false),
      );
    }
  }

  /// Performs a single biometric prompt and rejects results from a backgrounded app.
  Future<void> _authenticateBiometrics({required bool enable}) async {
    if (!_current.capabilities.canAuthenticate) {
      _update(_current.copyWith(message: TextConstants.biometricUnavailable));
      return;
    }
    final operation = _beginOperation(biometric: true);
    try {
      final result = await ref.read(biometricServiceProvider).authenticate();
      if (!ref.mounted || operation != _operation || _backgroundAt != null) {
        return;
      }
      if (result == BiometricResult.success) {
        await _commit(
          _current.record!.copyWith(
            biometricsEnabled: enable ? true : null,
            failedAttempts: 0,
            clearLockout: true,
            lastAuthenticatedAt: _now,
          ),
          AuthenticationStatus.unlocked,
          operation,
        );
        _scheduleLockoutExpiry(_current.record);
      } else {
        _update(
          _current.copyWith(
            message: switch (result) {
              BiometricResult.canceled => TextConstants.biometricCanceled,
              BiometricResult.lockedOut => TextConstants.biometricLockedOut,
              BiometricResult.unavailable => TextConstants.biometricUnavailable,
              _ => TextConstants.biometricFailed,
            },
          ),
        );
      }
    } catch (_) {
      _storageError();
    } finally {
      _endOperation();
    }
  }

  /// Cancels a biometric prompt so the PIN remains available.
  Future<void> cancelBiometrics() =>
      ref.read(biometricServiceProvider).cancel();

  /// Persists the selected inactivity and background lock duration.
  Future<void> setAutoLock(AutoLockDuration duration) async {
    if (_current.isBusy || _current.status != AuthenticationStatus.unlocked) {
      return;
    }
    await _savePreferences(_current.record!.copyWith(autoLock: duration));
  }

  /// Saves security preferences without exposing a partially saved state.
  Future<void> _savePreferences(AuthenticationRecord record) async {
    final operation = _beginOperation();
    try {
      await _commit(record, AuthenticationStatus.unlocked, operation);
    } catch (_) {
      _storageError();
    } finally {
      _endOperation();
    }
  }

  /// Writes secure data and prevents a late result from unlocking in the background.
  Future<void> _commit(
    AuthenticationRecord record,
    AuthenticationStatus status,
    int operation,
  ) async {
    await ref.read(authenticationServiceProvider).save(record);
    if (!ref.mounted) return;
    _update(
      _current.copyWith(
        record: record,
        status: operation == _operation && _backgroundAt == null
            ? status
            : AuthenticationStatus.locked,
        clearMessage: true,
      ),
    );
  }

  /// Marks a single authentication operation as busy.
  int _beginOperation({bool biometric = false}) {
    _idleTimer?.cancel();
    _update(
      _current.copyWith(
        isBusy: true,
        isBiometricPrompt: biometric,
        clearMessage: true,
      ),
    );
    return ++_operation;
  }

  /// Releases the busy state and restores the inactivity timer.
  void _endOperation() {
    if (!ref.mounted || !state.hasValue) return;
    _update(_current.copyWith(isBusy: false, isBiometricPrompt: false));
    recordInteraction();
  }

  /// Displays storage failures without changing the current lock state.
  void _storageError() {
    if (ref.mounted && state.hasValue) {
      _update(
        _current.copyWith(message: TextConstants.authenticationStorageError),
      );
    }
  }

  /// Locks immediately when explicitly requested or when inactivity expires.
  void lock() {
    if (!state.hasValue || _current.record == null) return;
    ++_operation;
    _idleTimer?.cancel();
    _update(
      _current.copyWith(
        status: AuthenticationStatus.locked,
        clearMessage: true,
      ),
    );
  }

  /// Restarts foreground inactivity timing after a touch or keyboard event.
  void recordInteraction() {
    _idleTimer?.cancel();
    if (!state.hasValue ||
        !_foreground ||
        _current.isBusy ||
        _current.status != AuthenticationStatus.unlocked) {
      return;
    }
    final duration = _current.record!.autoLock.duration;
    if (duration > Duration.zero) _idleTimer = Timer(duration, lock);
  }

  /// Hides inactive content and enforces the elapsed background lock policy.
  void handleLifecycle(AppLifecycleState lifecycle) {
    _foreground = lifecycle == AppLifecycleState.resumed;
    if (!state.hasValue) return;
    _update(_current.copyWith(isObscured: !_foreground));
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      _backgroundAt ??= _now;
      _idleTimer?.cancel();
      if (_current.isBusy ||
          _current.record?.autoLock == AutoLockDuration.immediately) {
        lock();
      }
      if (_current.isBusy) unawaited(cancelBiometrics());
    } else if (lifecycle == AppLifecycleState.resumed) {
      final since = _backgroundAt;
      _backgroundAt = null;
      if (since != null &&
          _current.status == AuthenticationStatus.unlocked &&
          _now.difference(since) >= _current.record!.autoLock.duration) {
        lock();
      }
      recordInteraction();
      unawaited(refreshCapabilities());
    }
  }

  /// Refreshes biometric availability after returning from device settings.
  Future<void> refreshCapabilities() async {
    if (_refreshing || !state.hasValue || _current.isBusy) return;
    _refreshing = true;
    try {
      final capabilities = await ref
          .read(biometricServiceProvider)
          .capabilities();
      if (ref.mounted && state.hasValue) {
        _update(_current.copyWith(capabilities: capabilities));
      }
    } finally {
      _refreshing = false;
    }
  }

  /// Rebuilds the PIN controls when a persisted lockout expires.
  void _scheduleLockoutExpiry(AuthenticationRecord? record) {
    _lockoutTimer?.cancel();
    final until = record?.lockedUntil;
    if (until == null || !until.isAfter(_now)) return;
    _lockoutTimer = Timer(until.difference(_now), () {
      if (ref.mounted && state.hasValue) {
        _update(_current.copyWith(clearMessage: true));
      }
    });
  }

  /// Publishes the next immutable authentication state.
  void _update(AuthenticationState next) => state = AsyncData(next);
}
