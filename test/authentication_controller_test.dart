import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/core/constants/text_constants.dart';
import 'package:smart_access/core/storage/secure_storage_service.dart';
import 'package:smart_access/features/authentication/controllers/authentication_controller.dart';
import 'package:smart_access/features/authentication/models/authentication_record.dart';
import 'package:smart_access/features/authentication/models/auto_lock_duration.dart';
import 'package:smart_access/features/authentication/models/biometric_capabilities.dart';
import 'package:smart_access/features/authentication/services/authentication_service.dart';
import 'package:smart_access/features/authentication/services/biometric_service.dart';
import 'package:smart_access/features/authentication/services/pin_service.dart';
import 'package:smart_access/features/authentication/states/authentication_state.dart';

import 'helpers/authentication_fakes.dart';

void main() {
  late MemorySecureStorage storage;
  late FakeBiometricService biometrics;
  late FakePinService pins;
  late DateTime now;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      secureStorageServiceProvider.overrideWithValue(storage),
      biometricServiceProvider.overrideWithValue(biometrics),
      pinServiceProvider.overrideWithValue(pins),
      authenticationClockProvider.overrideWithValue(() => now),
    ],
  );

  Future<AuthenticationController> initialize({
    bool existingPin = false,
    bool biometricEnabled = false,
  }) async {
    if (existingPin) {
      await AuthenticationService(storage).save(
        AuthenticationRecord(
          credential: await pins.create('123456'),
          biometricsEnabled: biometricEnabled,
        ),
      );
    }
    await container.read(authenticationControllerProvider.future);
    return container.read(authenticationControllerProvider.notifier);
  }

  AuthenticationState current() =>
      container.read(authenticationControllerProvider).requireValue;

  setUp(() {
    storage = MemorySecureStorage();
    biometrics = FakeBiometricService();
    pins = FakePinService();
    now = DateTime.utc(2026, 11, 11, 8);
    container = makeContainer();
  });
  tearDown(() => container.dispose());

  test('requires setup and rejects mismatched or malformed PINs', () async {
    final controller = await initialize();
    expect(current().status, AuthenticationStatus.setupRequired);
    await controller.createPin('123456', '654321');
    expect(storage.values, isEmpty);
    await controller.createPin('12345', '12345');
    expect(storage.values, isEmpty);
    expect(current().status, AuthenticationStatus.setupRequired);
  });

  test(
    'setup persists the verifier and a new app session starts locked',
    () async {
      final controller = await initialize();
      await controller.createPin('123456', '123456');
      expect(current().status, AuthenticationStatus.unlocked);
      expect(current().record!.lastAuthenticatedAt, now);
      expect(storage.values.values.single.contains('123456'), isFalse);
      container.dispose();
      container = makeContainer();
      await container.read(authenticationControllerProvider.future);
      expect(current().status, AuthenticationStatus.locked);
      expect(current().record!.lastAuthenticatedAt, now);
    },
  );

  test('failed secure write does not unlock setup or existing PIN', () async {
    final controller = await initialize();
    storage.failWrite = true;
    await controller.createPin('123456', '123456');
    expect(current().status, AuthenticationStatus.setupRequired);
    storage.failWrite = false;
    await controller.createPin('123456', '123456');
    controller.lock();
    storage.failWrite = true;
    await controller.unlockWithPin('123456');
    expect(current().status, AuthenticationStatus.locked);
    expect(current().message, TextConstants.authenticationStorageError);
  });

  test('five incorrect attempts persist a restart-safe lockout', () async {
    var controller = await initialize(existingPin: true);
    for (var i = 0; i < 5; i++) {
      await controller.unlockWithPin('654321');
    }
    expect(controller.isPinLockedOut, isTrue);
    await controller.unlockWithPin('123456');
    expect(current().status, AuthenticationStatus.locked);
    container.dispose();
    container = makeContainer();
    await container.read(authenticationControllerProvider.future);
    controller = container.read(authenticationControllerProvider.notifier);
    expect(controller.isPinLockedOut, isTrue);
    now = now.add(const Duration(seconds: 31));
    await controller.unlockWithPin('123456');
    expect(current().status, AuthenticationStatus.unlocked);
    expect(current().record!.failedAttempts, 0);
    expect(current().record!.lockedUntil, isNull);
  });

  test('expired lockout starts a new attempt group', () async {
    final controller = await initialize(existingPin: true);
    for (var i = 0; i < 5; i++) {
      await controller.unlockWithPin('654321');
    }
    now = now.add(const Duration(seconds: 31));
    await controller.unlockWithPin('654321');
    expect(current().record!.failedAttempts, 1);
    expect(controller.isPinLockedOut, isFalse);
  });

  test('biometrics must pass a challenge before being enabled', () async {
    final controller = await initialize(existingPin: true);
    await controller.unlockWithPin('123456');
    biometrics.result = BiometricResult.canceled;
    await controller.setBiometricsEnabled(true);
    expect(current().record!.biometricsEnabled, isFalse);
    biometrics.result = BiometricResult.success;
    await controller.setBiometricsEnabled(true);
    expect(current().record!.biometricsEnabled, isTrue);
    controller.lock();
    now = now.add(const Duration(seconds: 1));
    await controller.unlockWithBiometrics();
    expect(current().status, AuthenticationStatus.unlocked);
    expect(current().record!.lastAuthenticatedAt, now);
    await controller.setBiometricsEnabled(false);
    expect(current().record!.biometricsEnabled, isFalse);
    controller.lock();
    final calls = biometrics.calls;
    await controller.unlockWithBiometrics();
    expect(biometrics.calls, calls);
    expect(current().status, AuthenticationStatus.locked);
  });

  for (final result in [
    BiometricResult.canceled,
    BiometricResult.failed,
    BiometricResult.lockedOut,
    BiometricResult.unavailable,
  ]) {
    test('biometric $result retains PIN fallback', () async {
      final controller = await initialize(
        existingPin: true,
        biometricEnabled: true,
      );
      biometrics.result = result;
      await controller.unlockWithBiometrics();
      expect(current().status, AuthenticationStatus.locked);
      expect(current().isBusy, isFalse);
      await controller.unlockWithPin('123456');
      expect(current().status, AuthenticationStatus.unlocked);
    });
  }

  test('delayed biometric result cannot unlock after backgrounding', () async {
    final controller = await initialize(
      existingPin: true,
      biometricEnabled: true,
    );
    biometrics.pending = Completer<BiometricResult>();
    final pending = controller.unlockWithBiometrics();
    controller.handleLifecycle(AppLifecycleState.inactive);
    controller.handleLifecycle(AppLifecycleState.paused);
    controller.handleLifecycle(AppLifecycleState.resumed);
    biometrics.pending!.complete(BiometricResult.success);
    await pending;
    expect(current().status, AuthenticationStatus.locked);
    expect(current().isBusy, isFalse);
    expect(biometrics.cancellations, greaterThan(0));
  });

  test(
    'native biometric inactive transition does not discard a valid result',
    () async {
      final controller = await initialize(
        existingPin: true,
        biometricEnabled: true,
      );
      biometrics.pending = Completer<BiometricResult>();
      final pending = controller.unlockWithBiometrics();
      controller.handleLifecycle(AppLifecycleState.inactive);
      biometrics.pending!.complete(BiometricResult.success);
      await pending;
      expect(current().isObscured, isTrue);
      controller.handleLifecycle(AppLifecycleState.resumed);
      expect(current().status, AuthenticationStatus.unlocked);
      expect(current().isObscured, isFalse);
    },
  );

  test('late PIN verification cannot unlock after backgrounding', () async {
    final controller = await initialize(existingPin: true);
    pins.pendingVerification = Completer<bool>();
    final pending = controller.unlockWithPin('123456');
    controller.handleLifecycle(AppLifecycleState.paused);
    controller.handleLifecycle(AppLifecycleState.resumed);
    pins.pendingVerification!.complete(true);
    await pending;
    expect(current().status, AuthenticationStatus.locked);
  });

  test(
    'background duration and immediate locking follow saved policy',
    () async {
      final controller = await initialize(existingPin: true);
      await controller.unlockWithPin('123456');
      await controller.setAutoLock(AutoLockDuration.thirtySeconds);
      controller.handleLifecycle(AppLifecycleState.paused);
      expect(current().isObscured, isTrue);
      now = now.add(const Duration(seconds: 15));
      controller.handleLifecycle(AppLifecycleState.resumed);
      expect(current().status, AuthenticationStatus.unlocked);
      controller.handleLifecycle(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 31));
      controller.handleLifecycle(AppLifecycleState.resumed);
      expect(current().status, AuthenticationStatus.locked);
      await controller.unlockWithPin('123456');
      await controller.setAutoLock(AutoLockDuration.immediately);
      controller.handleLifecycle(AppLifecycleState.paused);
      controller.handleLifecycle(AppLifecycleState.resumed);
      expect(current().status, AuthenticationStatus.locked);
    },
  );

  testWidgets('foreground activity resets the inactivity timer', (
    tester,
  ) async {
    final controller = await initialize(existingPin: true);
    await controller.unlockWithPin('123456');
    await controller.setAutoLock(AutoLockDuration.thirtySeconds);
    await tester.pump(const Duration(seconds: 20));
    controller.recordInteraction();
    await tester.pump(const Duration(seconds: 20));
    expect(current().status, AuthenticationStatus.unlocked);
    await tester.pump(const Duration(seconds: 11));
    expect(current().status, AuthenticationStatus.locked);
    container.dispose();
    container = makeContainer();
  });

  test('corrupt secure record fails closed and remains untouched', () async {
    storage.values['authentication.record.v1'] = '{invalid';
    await expectLater(
      container.read(authenticationControllerProvider.future),
      throwsA(isA<FormatException>()),
    );
    expect(container.read(authenticationControllerProvider).hasError, isTrue);
    expect(storage.values.values.single, '{invalid');
  });

  test(
    'secure model round trip preserves settings and validates credential data',
    () async {
      final record = AuthenticationRecord(
        credential: await pins.create('123456'),
        autoLock: AutoLockDuration.fiveMinutes,
        biometricsEnabled: true,
        failedAttempts: 2,
        lastAuthenticatedAt: now,
      );
      final restored = AuthenticationRecord.fromJson(
        jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
      );
      expect(restored.autoLock, AutoLockDuration.fiveMinutes);
      expect(restored.biometricsEnabled, isTrue);
      expect(restored.lastAuthenticatedAt, now);
      expect(restored.failedAttempts, 2);
      final invalid = record.toJson();
      invalid['credential'] = {'salt': 'AA==', 'hash': 'AA==', 'iterations': 1};
      expect(
        () => AuthenticationRecord.fromJson(invalid),
        throwsFormatException,
      );
    },
  );
}
