import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../helpers/tracking_formatters.dart';
import 'tracking_metric_tile.dart';

class TrackingMetrics extends StatelessWidget {
  const TrackingMetrics({
    required this.distance,
    required this.duration,
    required this.points,
    this.speed,
    super.key,
  });
  final double distance;
  final Duration duration;
  final int points;
  final double? speed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
      final columns = (constraints.maxWidth / (150 * scale)).floor().clamp(
        1,
        4,
      );
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: TrackingMetricTile(
              label: TextConstants.trackingDistance,
              value: TextConstants.distanceValue(distance),
              icon: Icons.route_rounded,
            ),
          ),
          SizedBox(
            width: width,
            child: TrackingMetricTile(
              label: TextConstants.trackingDuration,
              value: formatTrackingDuration(duration),
              icon: Icons.timer_outlined,
            ),
          ),
          if (speed != null)
            SizedBox(
              width: width,
              child: TrackingMetricTile(
                label: TextConstants.trackingSpeed,
                value: TextConstants.speedValue(speed!),
                icon: Icons.speed_rounded,
              ),
            ),
          SizedBox(
            width: width,
            child: TrackingMetricTile(
              label: TextConstants.trackingSamples,
              value: points.toString(),
              icon: Icons.timeline_rounded,
            ),
          ),
        ],
      );
    },
  );
}
