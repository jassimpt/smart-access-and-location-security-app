import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../../location/models/location_snapshot.dart';
import '../../location/widgets/location_map.dart';
import '../../location/widgets/location_value.dart';
import '../controllers/geofence_controller.dart';
import '../widgets/delete_geofence_button.dart';

class GeofenceDetailScreen extends ConsumerWidget {
  const GeofenceDetailScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(geofenceControllerProvider);
    final fence = state.fences.where((fence) => fence.id == id).firstOrNull;
    return AppPage(
      children: [
        Text(
          fence?.name ?? TextConstants.geofences,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => context.go(RoutePaths.geofences),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(TextConstants.backToGeofences),
          ),
        ),
        const SizedBox(height: 20),
        if (!state.initialized && !state.loadFailed)
          const Center(child: CircularProgressIndicator())
        else if (fence == null)
          Text(
            state.loadFailed
                ? TextConstants.geofenceLoadFailed
                : TextConstants.geofenceNotFound,
          )
        else ...[
          LocationMap(
            snapshot: LocationSnapshot(
              latitude: fence.latitude,
              longitude: fence.longitude,
              accuracy: 0,
              recordedAt: fence.updatedAt,
            ),
            title: TextConstants.geofenceBoundary,
            boundaryRadius: fence.radiusMetres,
            markerLabel: TextConstants.selectedCenter,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LocationValue(
                    label: TextConstants.latitude,
                    value: fence.latitude.toStringAsFixed(6),
                  ),
                  LocationValue(
                    label: TextConstants.longitude,
                    value: fence.longitude.toStringAsFixed(6),
                  ),
                  LocationValue(
                    label: TextConstants.radius,
                    value: TextConstants.radiusMetres(fence.radiusMetres),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () => context.go(RoutePaths.geofenceEdit(fence.id)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(TextConstants.editGeofence),
              ),
              DeleteGeofenceButton(id: fence.id, returnToList: true),
            ],
          ),
          if (state.message != null) ...[
            const SizedBox(height: 16),
            Text(state.message!),
          ],
        ],
      ],
    );
  }
}
