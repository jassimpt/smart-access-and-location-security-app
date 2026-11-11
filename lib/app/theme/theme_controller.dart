import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_service.dart';
import '../bootstrap.dart';
import 'theme_state.dart';

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() =>
      ThemeState(mode: ref.watch(appInitializationProvider).requireValue);

  /// Saves the appearance before applying it to the app.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.isSaving || (state.mode == mode && !state.hasSaveError)) return;
    final previousMode = state.mode;
    state = ThemeState(mode: previousMode, isSaving: true);
    try {
      await ref.read(preferencesServiceProvider).saveThemeMode(mode);
      if (ref.mounted) state = ThemeState(mode: mode);
    } catch (_) {
      if (ref.mounted) {
        state = ThemeState(mode: previousMode, hasSaveError: true);
      }
    }
  }
}
