import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../../authentication/widgets/security_settings.dart';
import '../widgets/appearance_settings.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/adaptive_columns.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      children: [
        const SectionHeader(
          title: TextConstants.settings,
          subtitle: TextConstants.settingsSubtitle,
        ),
        AdaptiveColumns(
          main: const SecuritySettings(),
          aside: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: TextConstants.appearance,
                subtitle: TextConstants.appearanceSubtitle,
              ),
              const AppearanceSettings(),
            ],
          ),
        ),
      ],
    );
  }
}
