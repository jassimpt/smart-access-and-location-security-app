import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';

class DeleteGeofenceDialog extends StatelessWidget {
  const DeleteGeofenceDialog({super.key});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(TextConstants.geofenceDeleteTitle),
    content: const Text(TextConstants.geofenceDeleteDescription),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text(TextConstants.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text(TextConstants.deleteGeofence),
      ),
    ],
  );
}
