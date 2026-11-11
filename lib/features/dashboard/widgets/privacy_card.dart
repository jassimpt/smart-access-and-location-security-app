import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';

class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(TextConstants.privacyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              TextConstants.privacyDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.go(RoutePaths.settings),
              icon: const Icon(Icons.palette_outlined),
              label: const Text(TextConstants.customizeAppearance),
            ),
          ],
        ),
      ),
    );
  }
}
