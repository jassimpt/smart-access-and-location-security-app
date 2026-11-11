import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../tracking/helpers/tracking_formatters.dart';
import '../controllers/dashboard_controller.dart';
import 'overview_feature_card.dart';

class OverviewFeatures extends ConsumerWidget {
  const OverviewFeatures({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (tracking, areas) = ref.watch(
      dashboardSummaryProvider.select(
        (summary) => (summary.tracking, summary.areas),
      ),
    );
    final trackingStatus = tracking.loadFailed
        ? TextConstants.dashboardUnavailable
        : !tracking.initialized
        ? TextConstants.dashboardLoadingSaved
        : tracking.isRunning
        ? TextConstants.trackingActive
        : tracking.session != null
        ? TextConstants.trackingPaused
        : TextConstants.dashboardTrackingIdle;
    final trackingDescription = !tracking.initialized
        ? TextConstants.dashboardTrackingDetails
        : tracking.session == null
        ? TextConstants.trackingSessionCount(tracking.history.length)
        : TextConstants.dashboardTrackingMetrics(
            TextConstants.distanceValue(tracking.session!.distanceMetres),
            formatTrackingDuration(tracking.elapsed),
          );
    final areasStatus = areas.loadFailed
        ? TextConstants.dashboardUnavailable
        : !areas.initialized
        ? TextConstants.dashboardLoadingSaved
        : TextConstants.geofenceCount(areas.fences.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
        final columns = constraints.maxWidth >= 320 * scale ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: OverviewFeatureCard(
                icon: Icons.route_rounded,
                title: TextConstants.tracking,
                status: trackingStatus,
                description: trackingDescription,
                onTap: () => context.go(RoutePaths.tracking),
              ),
            ),
            SizedBox(
              width: width,
              child: OverviewFeatureCard(
                icon: Icons.radar_rounded,
                title: TextConstants.geofences,
                status: areasStatus,
                description: areas.isMonitoring
                    ? TextConstants.monitoringActive
                    : TextConstants.monitoringStopped,
                onTap: () => context.go(RoutePaths.geofences),
              ),
            ),
          ],
        );
      },
    );
  }
}
