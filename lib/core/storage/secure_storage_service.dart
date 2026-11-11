import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider(
  (ref) => const SecureStorageService(),
);

class SecureStorageService {
  const SecureStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// Reads a sensitive value from platform secure storage.
  Future<String?> read(String key) => _storage.read(key: key);

  /// Writes a sensitive value to platform secure storage.
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Removes a sensitive value from platform secure storage.
  Future<void> delete(String key) => _storage.delete(key: key);
}
