import '../models/authentication_record.dart';
import '../models/biometric_capabilities.dart';

enum AuthenticationStatus { setupRequired, locked, unlocked }

class AuthenticationState {
  const AuthenticationState({
    required this.status,
    this.record,
    this.capabilities = const BiometricCapabilities(),
    this.isBusy = false,
    this.isBiometricPrompt = false,
    this.isObscured = false,
    this.message,
  });

  final AuthenticationStatus status;
  final AuthenticationRecord? record;
  final BiometricCapabilities capabilities;
  final bool isBusy;
  final bool isBiometricPrompt;
  final bool isObscured;
  final String? message;

  /// Updates view state without changing unrelated authentication data.
  AuthenticationState copyWith({
    AuthenticationStatus? status,
    AuthenticationRecord? record,
    BiometricCapabilities? capabilities,
    bool? isBusy,
    bool? isBiometricPrompt,
    bool? isObscured,
    String? message,
    bool clearMessage = false,
  }) => AuthenticationState(
    status: status ?? this.status,
    record: record ?? this.record,
    capabilities: capabilities ?? this.capabilities,
    isBusy: isBusy ?? this.isBusy,
    isBiometricPrompt: isBiometricPrompt ?? this.isBiometricPrompt,
    isObscured: isObscured ?? this.isObscured,
    message: clearMessage ? null : message ?? this.message,
  );
}
