import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/text_constants.dart';
import '../models/auto_lock_duration.dart';
import '../models/biometric_capabilities.dart';

/// Returns the user-facing auto-lock duration.
String autoLockLabel(AutoLockDuration duration) => switch (duration) {
  AutoLockDuration.immediately => TextConstants.lockImmediately,
  AutoLockDuration.thirtySeconds => TextConstants.lockAfterThirtySeconds,
  AutoLockDuration.oneMinute => TextConstants.lockAfterOneMinute,
  AutoLockDuration.fiveMinutes => TextConstants.lockAfterFiveMinutes,
};

/// Describes the enrolled biometric types or the current availability problem.
String biometricDescription(BiometricCapabilities capabilities) {
  if (capabilities.checkFailed) return TextConstants.biometricCheckFailed;
  if (!capabilities.hasHardware) return TextConstants.biometricsNotSupported;
  if (capabilities.enrolledTypes.isEmpty) {
    return TextConstants.biometricsNotEnrolled;
  }
  final labels = <String>{};
  for (final type in capabilities.enrolledTypes) {
    labels.add(switch (type) {
      BiometricType.face => TextConstants.faceAvailable,
      BiometricType.fingerprint => TextConstants.fingerprintAvailable,
      BiometricType.iris => TextConstants.irisAvailable,
      _ => TextConstants.deviceBiometrics,
    });
  }
  if (labels.length > 1) labels.remove(TextConstants.deviceBiometrics);
  return labels.join(', ');
}

/// Formats authentication timestamps using the device's locale and time format.
String lastAuthenticationLabel(BuildContext context, DateTime? timestamp) {
  if (timestamp == null) return TextConstants.noAuthentication;
  final localizations = MaterialLocalizations.of(context);
  final local = timestamp.toLocal();
  return TextConstants.authenticationTime(
    localizations.formatMediumDate(local),
    localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    ),
  );
}
