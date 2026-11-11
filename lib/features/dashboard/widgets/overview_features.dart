import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/controllers/authentication_controller.dart';

import '../../../core/constants/text_constants.dart';
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
              child: const OverviewFeatureCard(
                icon: Icons.my_location_rounded,
                title: TextConstants.locationAwareness,
                description: TextConstants.locationDescription,
              ),
            ),
            SizedBox(
              width: width,
              child: const OverviewFeatureCard(
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
