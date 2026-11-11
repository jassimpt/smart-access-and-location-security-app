import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/tracking_controller.dart';
import '../widgets/tracking_controls.dart';
import '../widgets/tracking_metrics.dart';
import '../widgets/tracking_map_overview.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/adaptive_columns.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(trackingControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingControllerProvider);
    return AppPage(
      children: [
        const SectionHeader(
          title: TextConstants.tracking,
          subtitle: TextConstants.trackingSubtitle,
        ),
        AdaptiveColumns(
          main: const TrackingMapOverview(),
          aside: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TrackingControls(),
              const SizedBox(height: 16),
              TrackingMetrics(
                distance: state.session?.distanceMetres ?? 0,
                duration: state.elapsed,
                speed: state.speed,
                points: state.session?.points.length ?? 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
