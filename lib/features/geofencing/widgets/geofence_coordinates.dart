import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../helpers/geofence_validators.dart';

class GeofenceCoordinates extends StatelessWidget {
  const GeofenceCoordinates({
    required this.latitude,
    required this.longitude,
    required this.enabled,
    required this.onPreview,
    super.key,
  });
  final TextEditingController latitude;
  final TextEditingController longitude;
  final bool enabled;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        key: const ValueKey('geofence-latitude'),
        controller: latitude,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        decoration: const InputDecoration(
          labelText: TextConstants.latitude,
          border: OutlineInputBorder(),
        ),
        validator: GeofenceValidators.latitude,
        onFieldSubmitted: (_) => onPreview(),
      ),
      const SizedBox(height: 16),
      TextFormField(
        key: const ValueKey('geofence-longitude'),
        controller: longitude,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        decoration: const InputDecoration(
          labelText: TextConstants.longitude,
          border: OutlineInputBorder(),
        ),
        validator: GeofenceValidators.longitude,
        onFieldSubmitted: (_) => onPreview(),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: enabled ? onPreview : null,
          icon: const Icon(Icons.map_outlined),
          label: const Text(TextConstants.previewCoordinates),
        ),
      ),
    ],
  );
}
