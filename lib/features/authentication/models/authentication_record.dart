import 'auto_lock_duration.dart';
import 'pin_credential.dart';

class AuthenticationRecord {
  const AuthenticationRecord({
    required this.credential,
    this.biometricsEnabled = false,
    this.autoLock = AutoLockDuration.immediately,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.lastAuthenticatedAt,
  });

  final PinCredential credential;
  final bool biometricsEnabled;
  final AutoLockDuration autoLock;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime? lastAuthenticatedAt;

  /// Restores the complete secure authentication record.
  factory AuthenticationRecord.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported authentication record');
    }
    final attempts = json['failedAttempts'] as int;
    final lockedUntil = json['lockedUntil'] == null
        ? null
        : DateTime.parse(json['lockedUntil'] as String);
    if (attempts < 0 ||
        attempts > 5 ||
        (attempts == 5 && lockedUntil == null)) {
      throw const FormatException('Invalid authentication attempt state');
    }
    return AuthenticationRecord(
      credential: PinCredential.fromJson(
        json['credential'] as Map<String, dynamic>,
      ),
      biometricsEnabled: json['biometricsEnabled'] as bool,
      autoLock: AutoLockDuration.values.firstWhere(
        (value) => value.name == json['autoLock'],
      ),
      failedAttempts: attempts,
      lockedUntil: lockedUntil,
      lastAuthenticatedAt: json['lastAuthenticatedAt'] == null
          ? null
          : DateTime.parse(json['lastAuthenticatedAt'] as String),
    );
  }

  /// Creates a record with updated preferences or authentication attempts.
  AuthenticationRecord copyWith({
    bool? biometricsEnabled,
    AutoLockDuration? autoLock,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockout = false,
    DateTime? lastAuthenticatedAt,
  }) => AuthenticationRecord(
    credential: credential,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    autoLock: autoLock ?? this.autoLock,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLockout ? null : lockedUntil ?? this.lockedUntil,
    lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
  );

  /// Serializes authentication data for a single secure storage write.
  Map<String, dynamic> toJson() => {
    'version': 1,
    'credential': credential.toJson(),
    'biometricsEnabled': biometricsEnabled,
    'autoLock': autoLock.name,
    'failedAttempts': failedAttempts,
    'lockedUntil': lockedUntil?.toUtc().toIso8601String(),
    'lastAuthenticatedAt': lastAuthenticatedAt?.toUtc().toIso8601String(),
  };
}
