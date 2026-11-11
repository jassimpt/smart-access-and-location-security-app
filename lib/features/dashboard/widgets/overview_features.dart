import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../authentication/controllers/authentication_controller.dart';
import '../../location/controllers/location_controller.dart';
import '../../location/states/location_state.dart';
import '../../tracking/controllers/tracking_controller.dart';
import 'overview_feature_card.dart';

class OverviewFeatures extends ConsumerWidget {
  const OverviewFeatures({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref
        .watch(authenticationControllerProvider)
        .asData
        ?.value
        .record;
    final locationState = ref.watch(locationControllerProvider);
    final trackingState = ref.watch(trackingControllerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: OverviewFeatureCard(
                status: record == null
                    ? TextConstants.notConfigured
                    : TextConstants.pinProtected,
                icon: Icons.fingerprint_rounded,
                title: TextConstants.deviceAccess,
                description: TextConstants.deviceAccessDescription,
              ),
            ),
            SizedBox(
              width: width,
              child: OverviewFeatureCard(
                onTap: () => context.go(RoutePaths.location),
                status: locationState.snapshot != null
                    ? (locationState.isCached
                          ? TextConstants.lastKnownPosition
                          : TextConstants.locationReady)
                    : switch (locationState.status) {
                        LocationStatus.initial => TextConstants.viewLocation,
                        LocationStatus.gpsDisabled =>
                          TextConstants.gpsDisabledTitle,
                        LocationStatus.permissionRequired ||
                        LocationStatus.permanentlyDenied =>
                          TextConstants.permissionNeeded,
                        LocationStatus.unavailable =>
                          TextConstants.locationUnavailableTitle,
                        LocationStatus.ready => TextConstants.gpsEnabled,
                      },
                icon: Icons.my_location_rounded,
                title: TextConstants.locationAwareness,
                description: TextConstants.locationDescription,
              ),
            ),
            SizedBox(
              width: width,
              child: OverviewFeatureCard(
                onTap: () => context.go(RoutePaths.tracking),
                status: trackingState.isRunning
                    ? TextConstants.trackingActive
                    : trackingState.session != null
                    ? TextConstants.trackingPaused
                    : trackingState.initialized
                    ? TextConstants.trackingSessionCount(
                        trackingState.history.length,
                      )
                    : TextConstants.viewHistory,
                icon: Icons.route_outlined,
                title: TextConstants.activityHistory,
                description: TextConstants.activityDescription,
              ),
            ),
          ],
        );
      },
    );
  }
}
