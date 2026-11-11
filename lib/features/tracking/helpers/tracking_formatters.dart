import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/text_constants.dart';
import '../models/tracking_session.dart';

/// Formats elapsed active time without wrapping after twenty-four hours.
String formatTrackingDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Formats the session timestamp using the device's locale and clock preference.
String formatTrackingTime(BuildContext context, DateTime timestamp) {
  final local = timestamp.toLocal();
  final localizations = MaterialLocalizations.of(context);
  return TextConstants.authenticationTime(
    localizations.formatMediumDate(local),
    localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    ),
  );
}

/// Builds separate polylines so pauses never create connecting route segments.
List<List<LatLng>> trackingRouteSegments(TrackingSession session) {
  final segments = <int, List<LatLng>>{};
  for (final point in session.points) {
    (segments[point.segment] ??= []).add(
      LatLng(point.latitude, point.longitude),
    );
  }
  return segments.values.toList(growable: false);
}
