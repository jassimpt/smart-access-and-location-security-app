import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../helpers/tracking_formatters.dart';
import '../models/tracking_session.dart';

class TrackingHistoryTile extends StatelessWidget {
  const TrackingHistoryTile({required this.session, super.key});
  final TrackingSession session;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Icon(
        Icons.route_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(formatTrackingTime(context, session.startedAt)),
      subtitle: Text(
        TextConstants.trackingSessionSummary(
          TextConstants.distanceValue(session.distanceMetres),
          formatTrackingDuration(
            Duration(milliseconds: session.elapsedMilliseconds),
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go(RoutePaths.trackingSession(session.id)),
    ),
  );
}
