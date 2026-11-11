import 'package:flutter/material.dart';

class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.isSaving = false,
    this.hasSaveError = false,
  });

  final ThemeMode mode;
  final bool isSaving;
  final bool hasSaveError;
}
