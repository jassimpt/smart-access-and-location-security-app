import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/geofence_controller.dart';
import 'delete_geofence_dialog.dart';

class DeleteGeofenceButton extends ConsumerWidget {
  const DeleteGeofenceButton({
    required this.id,
    this.returnToList = false,
    super.key,
  });
  final String id;
  final bool returnToList;

  /// Confirms deletion of exactly one saved area.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteGeofenceDialog(),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(geofenceControllerProvider.notifier).deleteGeofence(id);
      if (returnToList &&
          context.mounted &&
          !ref
              .read(geofenceControllerProvider)
              .fences
              .any((fence) => fence.id == id)) {
        context.go(RoutePaths.geofences);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: ref.watch(geofenceControllerProvider).isBusy
        ? null
        : () => _confirm(context, ref),
    icon: const Icon(Icons.delete_outline_rounded),
    label: const Text(TextConstants.deleteGeofence),
  );
}
