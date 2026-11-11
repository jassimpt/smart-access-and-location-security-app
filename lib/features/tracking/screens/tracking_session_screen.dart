import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/tracking_controller.dart';
import '../widgets/session_metadata.dart';
import '../widgets/tracking_metrics.dart';
import '../widgets/tracking_route_preview.dart';

class TrackingSessionScreen extends ConsumerWidget {
  const TrackingSessionScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    final session = state.history
        .where((session) => session.id == sessionId)
        .firstOrNull;
    return AppPage(
      children: [
        Text(
          TextConstants.sessionDetails,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => context.go(RoutePaths.trackingHistory),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(TextConstants.backToHistory),
          ),
        ),
        const SizedBox(height: 20),
        if (!state.initialized && !state.loadFailed)
          const Center(child: CircularProgressIndicator())
        else if (session == null)
          Text(
            state.loadFailed
                ? TextConstants.trackingLoadFailed
                : TextConstants.trackingSessionUnavailable,
          )
        else ...[
          SessionMetadata(session: session),
          const SizedBox(height: 20),
          TrackingMetrics(
            distance: session.distanceMetres,
            duration: Duration(milliseconds: session.elapsedMilliseconds),
            points: session.points.length,
          ),
          const SizedBox(height: 20),
          TrackingRoutePreview(session: session, historical: true),
        ],
      ],
    );
  }
}
