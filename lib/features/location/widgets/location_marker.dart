import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';

class LocationMarker extends StatelessWidget {
  const LocationMarker({this.label = TextConstants.mapMarker, super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 4,
        ),
      ),
      child: Icon(
        Icons.my_location_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  );
}
