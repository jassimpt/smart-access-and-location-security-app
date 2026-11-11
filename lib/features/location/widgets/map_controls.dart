import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    required this.onCenter,
    required this.onZoomIn,
    required this.onZoomOut,
    super.key,
  });
  final VoidCallback onCenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 3,
        shadowColor: Theme.of(
          context,
        ).colorScheme.shadow.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onCenter,
              tooltip: TextConstants.centerMap,
              icon: const Icon(Icons.my_location_rounded),
            ),
            IconButton(
              onPressed: onZoomIn,
              tooltip: TextConstants.zoomIn,
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              onPressed: onZoomOut,
              tooltip: TextConstants.zoomOut,
              icon: const Icon(Icons.remove_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}
