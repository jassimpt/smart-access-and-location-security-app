import 'package:flutter/material.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/helpers/colors.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.heroBackground,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_rounded, size: 15, color: AppColors.heroMuted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                TextConstants.onDevice,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  color: AppColors.heroMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          TextConstants.welcomeTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.heroForeground,
            fontSize: 25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          TextConstants.overviewSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.heroMuted),
        ),
      ],
    ),
  );
}
