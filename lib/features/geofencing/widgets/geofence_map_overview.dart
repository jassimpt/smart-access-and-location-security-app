import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/text_constants.dart';
import '../../location/controllers/location_controller.dart';
import '../../location/models/location_snapshot.dart';
import '../../location/models/map_boundary.dart';
import '../../location/widgets/location_map.dart';
import '../controllers/geofence_controller.dart';

class GeofenceMapOverview extends ConsumerWidget {
  const GeofenceMapOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fences = ref.watch(
      geofenceControllerProvider.select((state) => state.fences),
    );
    final position = ref.watch(
      locationControllerProvider.select((state) => state.snapshot),
    );
    return LocationMap(
      snapshot:
          position ??
          LocationSnapshot(
            latitude: 0,
            longitude: 0,
            accuracy: 0,
            recordedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
      title: TextConstants.areaMap,
      showPositionMarker: false,
      initialZoom: position == null ? 2 : null,
      boundaries: [
        for (final fence in fences)
          MapBoundary(
            center: LatLng(fence.latitude, fence.longitude),
            radius: fence.radiusMetres,
            label: fence.name,
          ),
      ],
    );
  }
}
