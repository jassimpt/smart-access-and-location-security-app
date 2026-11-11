import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/text_constants.dart';
import '../models/biometric_capabilities.dart';

final biometricServiceProvider = Provider((ref) => BiometricService());

class BiometricService {
  BiometricService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  /// Checks hardware and enrolled biometric types without blocking PIN access.
  Future<BiometricCapabilities> capabilities() async {
    try {
      final hardware = await _authentication.canCheckBiometrics;
      final types = hardware
          ? await _authentication.getAvailableBiometrics()
          : <BiometricType>[];
      return BiometricCapabilities(
        hasHardware: hardware,
        enrolledTypes: List.unmodifiable(types),
      );
    } catch (_) {
      return const BiometricCapabilities(checkFailed: true);
    }
  }

  /// Requests biometrics only, leaving the app PIN as a separate fallback.
  Future<BiometricResult> authenticate() async {
    try {
      final success = await _authentication.authenticate(
        localizedReason: TextConstants.biometricReason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
      );
      return success ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => BiometricResult.canceled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } catch (_) {
      return BiometricResult.unavailable;
    }
  }

  /// Cancels a prompt when the app leaves the foreground.
  Future<void> cancel() async {
    try {
      await _authentication.stopAuthentication();
    } catch (_) {}
  }
}
