import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/info_disclosure.dart';
import '../../location/widgets/location_notice.dart';
import '../controllers/geofence_controller.dart';

class GeofenceMonitorControls extends ConsumerWidget {
  const GeofenceMonitorControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(geofenceControllerProvider);
    final controller = ref.read(geofenceControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isMonitoring
                  ? TextConstants.monitoringActive
                  : TextConstants.monitoringStopped,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (state.loadFailed)
                  FilledButton(
                    onPressed: state.isBusy ? null : controller.initialize,
                    child: const Text(TextConstants.retry),
                  )
                else
                  FilledButton.icon(
                    onPressed:
                        state.isBusy ||
                            !state.initialized ||
                            state.fences.isEmpty
                        ? null
                        : state.isMonitoring
                        ? () => controller.stopMonitoring()
                        : controller.startMonitoring,
                    icon: Icon(
                      state.isMonitoring
                          ? Icons.pause_rounded
                          : Icons.radar_rounded,
                    ),
                    label: Text(
                      state.isMonitoring
                          ? TextConstants.stopMonitoring
                          : TextConstants.startMonitoring,
                    ),
                  ),
                TextButton(
                  onPressed: () => context.go(RoutePaths.location),
                  child: const Text(TextConstants.viewLocation),
                ),
              ],
            ),
            const InfoDisclosure(
              paragraphs: [
                TextConstants.monitoringHint,
                TextConstants.monitoringAccuracyHint,
                TextConstants.monitoringNotificationHint,
              ],
            ),
            if (state.isBusy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (state.message != null) LocationNotice(message: state.message!),
            if (state.notificationWarning != null)
              LocationNotice(message: state.notificationWarning!),
          ],
        ),
      ),
    );
  }
}
