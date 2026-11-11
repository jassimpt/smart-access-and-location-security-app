import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../models/geofence_event.dart';

/// Describes a monitored boundary's confident position state.
String geofencePresenceLabel(GeofencePresence presence) => switch (presence) {
  GeofencePresence.unknown => TextConstants.geofenceUnknown,
  GeofencePresence.inside => TextConstants.geofenceInside,
  GeofencePresence.outside => TextConstants.geofenceOutside,
};

/// Formats the latest transition from this foreground monitoring session.
String geofenceEventLabel(BuildContext context, GeofenceEvent event) {
  final local = event.occurredAt.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final time = TextConstants.authenticationTime(
    localizations.formatMediumDate(local),
    localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    ),
  );
  return '${event.transition == GeofenceTransition.entered ? TextConstants.geofenceEntered : TextConstants.geofenceExited} • $time';
}
