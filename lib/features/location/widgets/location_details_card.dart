import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../helpers/location_display_helpers.dart';
import '../states/location_state.dart';
import 'location_value.dart';
import '../../../core/widgets/value_grid.dart';

class LocationDetailsCard extends StatelessWidget {
  const LocationDetailsCard({required this.state, super.key});
  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isCached
                  ? TextConstants.lastKnownPosition
                  : TextConstants.currentPosition,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.isCached
                  ? TextConstants.savedLocationExplanation
                  : TextConstants.liveLocationExplanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ValueGrid(
              children: [
                LocationValue(
                  label: TextConstants.latitude,
                  value: snapshot.latitude.toStringAsFixed(6),
                ),
                LocationValue(
                  label: TextConstants.longitude,
                  value: snapshot.longitude.toStringAsFixed(6),
                ),
                LocationValue(
                  label: TextConstants.gpsAccuracy,
                  value: TextConstants.accuracyMetres(
                    snapshot.accuracy.toStringAsFixed(1),
                  ),
                ),
                LocationValue(
                  label: TextConstants.locationPrecision,
                  value: locationPrecisionLabel(snapshot),
                ),
                LocationValue(
                  label: TextConstants.recordedAt,
                  value: locationTimestampLabel(context, snapshot.recordedAt),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 20),
            LocationValue(
              label: state.isAddressCached
                  ? TextConstants.savedAddress
                  : TextConstants.address,
              value:
                  snapshot.address ??
                  (state.isResolvingAddress
                      ? TextConstants.resolvingAddress
                      : TextConstants.addressUnavailable),
            ),
          ],
        ),
      ),
    );
  }
}
