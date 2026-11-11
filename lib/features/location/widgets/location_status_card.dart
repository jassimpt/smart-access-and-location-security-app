import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/location_controller.dart';
import '../states/location_state.dart';
import 'location_notice.dart';

class LocationStatusCard extends ConsumerWidget {
  const LocationStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationControllerProvider);
    final controller = ref.read(locationControllerProvider.notifier);
    final (title, description, label, action, icon) = switch (state.status) {
      LocationStatus.initial => (
        TextConstants.checkingLocation,
        TextConstants.locationPermissionExplanation,
        TextConstants.refreshLocation,
        controller.refresh,
        Icons.my_location_rounded,
      ),
      LocationStatus.permissionRequired => (
        TextConstants.locationPermissionTitle,
        TextConstants.locationPermissionExplanation,
        TextConstants.allowLocation,
        controller.requestAccess,
        Icons.location_on_outlined,
      ),
      LocationStatus.permanentlyDenied => (
        TextConstants.permissionBlockedTitle,
        TextConstants.permissionBlockedDescription,
        TextConstants.openAppSettings,
        controller.openAppSettings,
        Icons.location_disabled_outlined,
      ),
      LocationStatus.gpsDisabled => (
        TextConstants.gpsDisabledTitle,
        TextConstants.gpsDisabledDescription,
        TextConstants.openLocationSettings,
        controller.openLocationSettings,
        Icons.location_disabled_outlined,
      ),
      LocationStatus.unavailable => (
        TextConstants.locationUnavailableTitle,
        TextConstants.locationUnavailableDescription,
        TextConstants.refreshLocation,
        controller.refresh,
        Icons.gps_not_fixed_rounded,
      ),
      LocationStatus.ready => (
        state.isBusy &&
                !state.isResolvingAddress &&
                (state.snapshot == null || state.isCached)
            ? TextConstants.locating
            : TextConstants.locationReady,
        state.isBusy &&
                !state.isResolvingAddress &&
                (state.snapshot == null || state.isCached)
            ? TextConstants.locatingDescription
            : TextConstants.locationReadyDescription,
        TextConstants.refreshLocation,
        controller.refresh,
        Icons.gps_fixed_rounded,
      ),
    };
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (state.status != LocationStatus.ready) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: state.isBusy ? null : action,
                  child: Text(label),
                ),
                if (state.status == LocationStatus.gpsDisabled ||
                    state.status == LocationStatus.permanentlyDenied)
                  OutlinedButton(
                    onPressed: state.isBusy ? null : controller.refresh,
                    child: const Text(TextConstants.refreshLocation),
                  ),
              ],
            ),
            if (state.isBusy) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
            if (state.message != null) LocationNotice(message: state.message!),
            if (state.storageWarning != null)
              LocationNotice(message: state.storageWarning!),
          ],
        ),
      ),
    );
  }
}
