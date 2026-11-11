import 'dart:async';
import 'dart:convert';

import 'package:local_auth/local_auth.dart';
import 'package:smart_access/core/storage/secure_storage_service.dart';
import 'package:smart_access/features/authentication/controllers/authentication_controller.dart';
import 'package:smart_access/features/authentication/models/authentication_record.dart';
import 'package:smart_access/features/authentication/models/biometric_capabilities.dart';
import 'package:smart_access/features/authentication/models/pin_credential.dart';
import 'package:smart_access/features/authentication/services/biometric_service.dart';
import 'package:smart_access/features/authentication/services/pin_service.dart';
import 'package:smart_access/features/authentication/states/authentication_state.dart';

class MemorySecureStorage implements SecureStorageService {
  final values = <String, String>{};
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('Read failed');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('Write failed');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FakePinService extends PinService {
  Completer<bool>? pendingVerification;

  @override
  Future<PinCredential> create(String pin) async => PinCredential(
    salt: base64Encode(List.filled(16, 0)),
    hash: base64Encode([...pin.codeUnits, ...List.filled(26, 0)]),
    iterations: 600000,
  );

  @override
  Future<bool> verify(String pin, PinCredential credential) async {
    if (pendingVerification != null) return pendingVerification!.future;
    return credential.hash == (await create(pin)).hash;
  }
}

class FakeBiometricService implements BiometricService {
  BiometricCapabilities available = const BiometricCapabilities(
    hasHardware: true,
    enrolledTypes: [BiometricType.fingerprint],
  );
  BiometricResult result = BiometricResult.success;
  Completer<BiometricResult>? pending;
  int calls = 0;
  int cancellations = 0;

  @override
  Future<BiometricCapabilities> capabilities() async => available;

  @override
  Future<BiometricResult> authenticate() async {
    calls++;
    return pending?.future ?? Future.value(result);
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }
}

class UnlockedAuthenticationController extends AuthenticationController {
  @override
  Future<AuthenticationState> build() async => AuthenticationState(
    status: AuthenticationStatus.unlocked,
    record: AuthenticationRecord(
      credential: await FakePinService().create('123456'),
    ),
  );
}
