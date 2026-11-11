import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/hive_service.dart';
import '../core/storage/preferences_service.dart';

final appInitializationProvider = FutureProvider<ThemeMode>((ref) async {
  await ref.read(hiveServiceProvider).initialize();
  return ref.read(preferencesServiceProvider).readThemeMode();
});
