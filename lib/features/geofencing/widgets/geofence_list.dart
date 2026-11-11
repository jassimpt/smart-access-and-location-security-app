import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/geofence_controller.dart';
import '../models/geofence_event.dart';
import 'geofence_card.dart';

class GeofenceList extends ConsumerWidget {
  const GeofenceList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(geofenceControllerProvider);
    if (!state.initialized) return const SizedBox.shrink();
    if (state.fences.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                TextConstants.geofenceEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(TextConstants.geofenceEmptyDescription),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final fence in state.fences) ...[
          GeofenceCard(
            fence: fence,
            monitoring: state.isMonitoring,
            presence: state.presences[fence.id] ?? GeofencePresence.unknown,
            event: state.events[fence.id],
            busy: state.isBusy,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
