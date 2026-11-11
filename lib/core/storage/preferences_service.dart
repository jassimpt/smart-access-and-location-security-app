import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider((ref) => PreferencesService());

class PreferencesService {
  PreferencesService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _themeKey = 'appearance.theme_mode';
  final SharedPreferencesAsync _preferences;

  /// Reads the saved appearance, defaulting to the device theme.
  Future<ThemeMode> readThemeMode() async {
    final savedMode = await _preferences.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }

  /// Persists the selected appearance.
  Future<void> saveThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeKey, mode.name);
}
