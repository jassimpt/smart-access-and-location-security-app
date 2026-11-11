import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/geofence_controller.dart';
import '../widgets/geofence_list.dart';
import '../widgets/geofence_map_overview.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/adaptive_columns.dart';
import '../widgets/geofence_monitor_controls.dart';

class GeofenceScreen extends ConsumerStatefulWidget {
  const GeofenceScreen({super.key});
  @override
  ConsumerState<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends ConsumerState<GeofenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(geofenceControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(geofenceControllerProvider);
    return AppPage(
      children: [
        const SectionHeader(
          title: TextConstants.geofences,
          subtitle: TextConstants.areasSubtitle,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: !state.initialized || state.isBusy
                ? null
                : () => context.go(RoutePaths.geofenceNew),
            icon: const Icon(Icons.add_rounded),
            label: const Text(TextConstants.addGeofence),
          ),
        ),
        const SizedBox(height: 16),
        AdaptiveColumns(
          main: const GeofenceMapOverview(),
          aside: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GeofenceMonitorControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          TextConstants.savedPlaces,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const GeofenceList(),
      ],
    );
  }
}
