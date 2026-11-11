import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../models/authentication_record.dart';

final authenticationServiceProvider = Provider(
  (ref) => AuthenticationService(ref.read(secureStorageServiceProvider)),
);

class AuthenticationService {
  const AuthenticationService(this._storage);
  static const _recordKey = 'authentication.record.v1';
  final SecureStorageService _storage;

  /// Loads authentication data, allowing storage errors to fail closed.
  Future<AuthenticationRecord?> load() async {
    final saved = await _storage.read(_recordKey);
    if (saved == null) return null;
    return AuthenticationRecord.fromJson(
      jsonDecode(saved) as Map<String, dynamic>,
    );
  }

  /// Persists credentials, preferences, and attempts atomically as one value.
  Future<void> save(AuthenticationRecord record) =>
      _storage.write(_recordKey, jsonEncode(record.toJson()));
}
