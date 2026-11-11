import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/geofence_controller.dart';
import '../widgets/geofence_editor_form.dart';

class GeofenceEditorScreen extends ConsumerWidget {
  const GeofenceEditorScreen({this.id, super.key});
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(geofenceControllerProvider);
    final existing = state.fences.where((fence) => fence.id == id).firstOrNull;
    return AppPage(
      children: [
        Text(
          id == null ? TextConstants.addGeofence : TextConstants.editGeofence,
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
        else if (state.loadFailed)
          const Text(TextConstants.geofenceLoadFailed)
        else if (id != null && existing == null)
          const Text(TextConstants.geofenceNotFound)
        else
          GeofenceEditorForm(key: ValueKey(id), existing: existing),
      ],
    );
  }
}
