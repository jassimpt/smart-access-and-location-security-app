import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../helpers/geofence_display_helpers.dart';
import '../models/geofence.dart';
import '../models/geofence_event.dart';
import 'delete_geofence_button.dart';

class GeofenceCard extends StatelessWidget {
  const GeofenceCard({
    required this.fence,
    required this.monitoring,
    this.presence = GeofencePresence.unknown,
    this.event,
    this.busy = false,
    super.key,
  });
  final Geofence fence;
  final bool monitoring;
  final GeofencePresence presence;
  final GeofenceEvent? event;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.place_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fence.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(TextConstants.radiusMetres(fence.radiusMetres)),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              monitoring
                  ? geofencePresenceLabel(presence)
                  : TextConstants.geofenceNotMonitoring,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (event != null) ...[
            const SizedBox(height: 16),
            const Text(TextConstants.lastGeofenceEvent),
            Text(geofenceEventLabel(context, event!)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () => context.go(RoutePaths.geofenceDetail(fence.id)),
                icon: const Icon(Icons.map_outlined),
                label: const Text(TextConstants.viewGeofence),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => context.go(RoutePaths.geofenceEdit(fence.id)),
                child: const Text(TextConstants.editGeofence),
              ),
              DeleteGeofenceButton(id: fence.id),
            ],
          ),
        ],
      ),
    ),
  );
}
