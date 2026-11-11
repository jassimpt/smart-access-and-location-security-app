import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../location/widgets/location_notice.dart';
import '../controllers/tracking_controller.dart';

class TrackingControls extends ConsumerWidget {
  const TrackingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    final controller = ref.read(trackingControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isRunning
                  ? TextConstants.trackingActive
                  : state.session != null
                  ? TextConstants.trackingPaused
                  : TextConstants.trackingReady,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              state.session != null && !state.isRunning
                  ? TextConstants.trackingPausedDescription
                  : TextConstants.trackingForegroundHint,
            ),
            const SizedBox(height: 12),
            const Text(TextConstants.trackingNotificationHint),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (state.loadFailed)
                  FilledButton(
                    onPressed: state.isBusy ? null : controller.initialize,
                    child: const Text(TextConstants.retry),
                  )
                else if (state.isRunning)
                  OutlinedButton.icon(
                    onPressed: state.isBusy ? null : () => controller.pause(),
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text(TextConstants.pauseTracking),
                  )
                else
                  FilledButton.icon(
                    onPressed: state.isBusy || !state.initialized
                        ? null
                        : controller.startOrResume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      state.session == null
                          ? TextConstants.startTracking
                          : TextConstants.resumeTracking,
                    ),
                  ),
                if (state.session != null)
                  FilledButton.icon(
                    onPressed: state.isBusy ? null : controller.stopAndSave,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text(TextConstants.stopTracking),
                  ),
                OutlinedButton.icon(
                  onPressed: () => context.go(RoutePaths.trackingHistory),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text(TextConstants.viewHistory),
                ),
                if (state.accessProblem != null)
                  TextButton(
                    onPressed: () => context.go(RoutePaths.location),
                    child: const Text(TextConstants.viewLocation),
                  ),
              ],
            ),
            if (state.isBusy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (state.message != null) LocationNotice(message: state.message!),
            if (state.storageWarning != null)
              LocationNotice(message: state.storageWarning!),
            if (state.notificationWarning != null)
              LocationNotice(message: state.notificationWarning!),
          ],
        ),
      ),
    );
  }
}
