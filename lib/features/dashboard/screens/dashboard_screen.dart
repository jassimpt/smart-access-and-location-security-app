import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../widgets/overview_features.dart';
import '../widgets/privacy_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      children: [
        Text(
          TextConstants.overview,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(TextConstants.welcomeTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          TextConstants.welcomeDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        const OverviewFeatures(),
        const SizedBox(height: 24),
        const PrivacyCard(),
      ],
    );
  }
}
