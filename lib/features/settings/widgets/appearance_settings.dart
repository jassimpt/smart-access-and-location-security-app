import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme_controller.dart';
import '../../../core/constants/text_constants.dart';
import 'theme_option_tile.dart';

class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThemeOptionTile(
          title: TextConstants.systemTheme,
          description: TextConstants.systemThemeDescription,
          icon: Icons.brightness_auto_outlined,
          selected: state.mode == ThemeMode.system,
          onTap: state.isSaving
              ? null
              : () => controller.setThemeMode(ThemeMode.system),
        ),
        const SizedBox(height: 12),
        ThemeOptionTile(
          title: TextConstants.lightTheme,
          description: TextConstants.lightThemeDescription,
          icon: Icons.light_mode_outlined,
          selected: state.mode == ThemeMode.light,
          onTap: state.isSaving
              ? null
              : () => controller.setThemeMode(ThemeMode.light),
        ),
        const SizedBox(height: 12),
        ThemeOptionTile(
          title: TextConstants.darkTheme,
          description: TextConstants.darkThemeDescription,
          icon: Icons.dark_mode_outlined,
          selected: state.mode == ThemeMode.dark,
          onTap: state.isSaving
              ? null
              : () => controller.setThemeMode(ThemeMode.dark),
        ),
        if (state.isSaving) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
        if (state.hasSaveError) ...[
          const SizedBox(height: 16),
          Text(
            TextConstants.themeSaveError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
