import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../../location/models/location_snapshot.dart';
import '../../location/widgets/location_map.dart';
import '../helpers/tracking_formatters.dart';
import '../models/tracking_session.dart';

class TrackingRoutePreview extends StatelessWidget {
  const TrackingRoutePreview({
    required this.session,
    this.historical = false,
    super.key,
  });
  final TrackingSession session;
  final bool historical;

  @override
  Widget build(BuildContext context) {
    if (session.points.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.gps_not_fixed_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                historical
                    ? TextConstants.sessionNoRoute
                    : TextConstants.trackingWaiting,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!historical) ...[
                const SizedBox(height: 8),
                const Text(TextConstants.trackingWaitingDescription),
              ],
            ],
          ),
        ),
      );
    }
    final point = session.points.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocationMap(
          snapshot: LocationSnapshot(
            latitude: point.latitude,
            longitude: point.longitude,
            accuracy: point.accuracy,
            recordedAt: point.recordedAt,
          ),
          routes: trackingRouteSegments(session),
          title: TextConstants.routePreview,
          fitRoute: historical,
        ),
      ],
    );
  }
}
