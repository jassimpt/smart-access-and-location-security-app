import 'package:flutter/material.dart';

import '../../../core/widgets/app_page.dart';
import '../widgets/overview_features.dart';
import '../widgets/dashboard_hero.dart';
import '../../../core/widgets/adaptive_columns.dart';
import '../widgets/privacy_card.dart';
import '../widgets/dashboard_device_status.dart';
import '../widgets/dashboard_location_card.dart';
import '../widgets/dashboard_refresh_controls.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      children: [
        DashboardHero(),
        SizedBox(height: 16),
        DashboardRefreshControls(),
        SizedBox(height: 16),
        DashboardLocationCard(),
        SizedBox(height: 20),
        AdaptiveColumns(
          main: OverviewFeatures(),
          aside: DashboardDeviceStatus(),
        ),
        SizedBox(height: 20),
        PrivacyCard(),
      ],
    );
  }
}
