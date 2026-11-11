import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final hiveServiceProvider = Provider((ref) => HiveService());

class HiveService {
  /// Initializes the local database directory.
  Future<void> initialize() => Hive.initFlutter();

  /// Registers a feature model adapter once before opening its box.
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  /// Opens a typed box owned by a feature service.
  Future<Box<T>> openBox<T>(String name) => Hive.openBox<T>(name);
}
