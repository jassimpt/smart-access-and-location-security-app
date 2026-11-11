import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../../authentication/widgets/security_settings.dart';
import '../widgets/appearance_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      children: [
        Text(TextConstants.settings, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          TextConstants.securityDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        const SecuritySettings(),
        const SizedBox(height: 32),
        Text(TextConstants.appearance, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          TextConstants.appearanceDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        const AppearanceSettings(),
      ],
    );
  }
}
