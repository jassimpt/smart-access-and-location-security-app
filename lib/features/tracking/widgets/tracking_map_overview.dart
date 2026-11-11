import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/text_constants.dart';
import '../../location/controllers/location_controller.dart';
import '../../location/models/location_snapshot.dart';
import '../../location/widgets/location_map.dart';
import '../controllers/tracking_controller.dart';
import 'tracking_route_preview.dart';

class TrackingMapOverview extends ConsumerWidget {
  const TrackingMapOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(
      trackingControllerProvider.select((state) => state.session),
    );
    final location = ref.watch(
      locationControllerProvider.select((state) => state.snapshot),
    );
    if (session != null && session.points.isNotEmpty) {
      return TrackingRoutePreview(session: session);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocationMap(
          snapshot:
              location ??
              LocationSnapshot(
                latitude: 0,
                longitude: 0,
                accuracy: 0,
                recordedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              ),
          title: TextConstants.routePreview,
          showPositionMarker: location != null,
          initialZoom: location == null ? 2 : null,
        ),
        if (session != null) ...[
          const SizedBox(height: 12),
          const Text(TextConstants.trackingWaiting),
        ],
      ],
    );
  }
}
