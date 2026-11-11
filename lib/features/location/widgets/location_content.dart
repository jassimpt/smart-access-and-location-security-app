import 'package:flutter/material.dart';
import '../../../core/widgets/adaptive_columns.dart';
import '../models/location_snapshot.dart';
import '../states/location_state.dart';
import 'location_details_card.dart';
import 'location_map.dart';
import 'location_status_card.dart';

class LocationContent extends StatelessWidget {
  const LocationContent({required this.state, super.key});
  final LocationState state;

  @override
  Widget build(BuildContext context) {
    if (state.snapshot == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LocationStatusCard(),
          const SizedBox(height: 16),
          LocationMap(
            snapshot: LocationSnapshot(
              latitude: 0,
              longitude: 0,
              accuracy: 0,
              recordedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            ),
            showPositionMarker: false,
            initialZoom: 2,
          ),
        ],
      );
    }
    return AdaptiveColumns(
      main: LocationMap(
        snapshot:
            state.snapshot ??
            LocationSnapshot(
              latitude: 0,
              longitude: 0,
              accuracy: 0,
              recordedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            ),
        showPositionMarker: state.snapshot != null,
        initialZoom: state.snapshot == null ? 2 : null,
      ),
      aside: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LocationStatusCard(),
          if (state.snapshot != null) ...[
            const SizedBox(height: 16),
            LocationDetailsCard(state: state),
          ],
        ],
      ),
    );
  }
}
