import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../../location/widgets/location_value.dart';
import '../helpers/tracking_formatters.dart';
import '../models/tracking_session.dart';

class SessionMetadata extends StatelessWidget {
  const SessionMetadata({required this.session, super.key});
  final TrackingSession session;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationValue(
            label: TextConstants.sessionStarted,
            value: formatTrackingTime(context, session.startedAt),
          ),
          if (session.endedAt != null)
            LocationValue(
              label: TextConstants.sessionEnded,
              value: formatTrackingTime(context, session.endedAt!),
            ),
        ],
      ),
    ),
  );
}
