import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../helpers/geofence_validators.dart';
import '../models/geofence.dart';

class GeofenceRadiusControl extends StatelessWidget {
  const GeofenceRadiusControl({
    required this.controller,
    required this.radius,
    required this.enabled,
    required this.onChanged,
    required this.onTextChanged,
    super.key,
  });
  final TextEditingController controller;
  final double radius;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        key: const ValueKey('geofence-radius'),
        controller: controller,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: TextConstants.radius,
          border: OutlineInputBorder(),
        ),
        validator: GeofenceValidators.radius,
        onChanged: onTextChanged,
      ),
      const SizedBox(height: 8),
      Slider(
        value: radius.clamp(Geofence.minRadius, Geofence.maxRadius),
        min: Geofence.minRadius,
        max: Geofence.maxRadius,
        divisions: 199,
        label: TextConstants.radiusMetres(radius),
        onChanged: enabled ? onChanged : null,
      ),
      Text(
        TextConstants.radiusMetres(radius),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    ],
  );
}
