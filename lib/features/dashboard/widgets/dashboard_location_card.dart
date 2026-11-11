import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/value_grid.dart';
import '../../location/helpers/location_display_helpers.dart';
import '../../location/widgets/location_value.dart';
import '../../location/widgets/location_map.dart';
import '../../location/widgets/location_notice.dart';
import '../controllers/dashboard_controller.dart';

class DashboardLocationCard extends ConsumerWidget {
  const DashboardLocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final position = summary.position;
    final location = summary.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (position != null)
          LocationMap(
            snapshot: position.snapshot,
            title: TextConstants.yourMap,
            height: 240,
          ),
        if (position != null) const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        position == null
                            ? TextConstants.dashboardSnapshot
                            : position.isCached
                            ? TextConstants.lastKnownPosition
                            : TextConstants.currentPosition,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => context.go(RoutePaths.location),
                      icon: const Icon(Icons.north_east_rounded, size: 20),
                      tooltip: TextConstants.viewLocation,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (position == null) ...[
                  const Text(TextConstants.dashboardLocationEmpty),
                  const SizedBox(height: 8),
                  const Text(TextConstants.dashboardLocationHint),
                ] else ...[
                  const SizedBox(height: 12),
                  ValueGrid(
                    minimumWidth: 120,
                    children: [
                      LocationValue(
                        label: TextConstants.latitude,
                        value: position.snapshot.latitude.toStringAsFixed(6),
                      ),
                      LocationValue(
                        label: TextConstants.longitude,
                        value: position.snapshot.longitude.toStringAsFixed(6),
                      ),
                      LocationValue(
                        label: TextConstants.gpsAccuracy,
                        value: TextConstants.accuracyMetres(
                          position.snapshot.accuracy.toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    locationTimestampLabel(
                      context,
                      position.snapshot.recordedAt,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (position.snapshot.address != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      position.snapshot.address!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
                if (location.isBusy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (location.message != null)
                  LocationNotice(message: location.message!),
                if (location.storageWarning != null)
                  LocationNotice(message: location.storageWarning!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
