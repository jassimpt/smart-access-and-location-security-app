import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/status_pill.dart';
import '../controllers/tracking_controller.dart';
import '../helpers/tracking_formatters.dart';

class TrackingHistorySummary extends ConsumerWidget {
  const TrackingHistorySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(
      trackingControllerProvider.select((state) => state.history),
    );
    if (history.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusPill(
          label: TextConstants.trackingSessionCount(history.length),
          icon: Icons.layers_outlined,
        ),
        StatusPill(
          label: TextConstants.distanceValue(
            history.fold<double>(
              0,
              (total, session) => total + session.distanceMetres,
            ),
          ),
          icon: Icons.route_rounded,
        ),
        StatusPill(
          label: formatTrackingDuration(
            Duration(
              milliseconds: history.fold<int>(
                0,
                (total, session) => total + session.elapsedMilliseconds,
              ),
            ),
          ),
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }
}
