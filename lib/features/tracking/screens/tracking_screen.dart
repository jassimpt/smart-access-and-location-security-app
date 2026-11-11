import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/tracking_controller.dart';
import '../widgets/tracking_controls.dart';
import '../widgets/tracking_metrics.dart';
import '../widgets/tracking_route_preview.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(trackingControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      ref.read(trackingControllerProvider.notifier).handleLifecycle(state);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingControllerProvider);
    return AppPage(
      children: [
        Text(
          TextConstants.tracking,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(TextConstants.trackingDescription),
        const SizedBox(height: 24),
        const TrackingControls(),
        if (state.session != null) ...[
          const SizedBox(height: 20),
          TrackingMetrics(
            distance: state.session!.distanceMetres,
            duration: state.elapsed,
            speed: state.speed,
            points: state.session!.points.length,
          ),
          const SizedBox(height: 20),
          TrackingRoutePreview(session: state.session!),
        ],
      ],
    );
  }
}
