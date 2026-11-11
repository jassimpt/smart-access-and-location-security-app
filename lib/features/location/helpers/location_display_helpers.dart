import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../models/location_snapshot.dart';

/// Formats the timestamp of a GPS fix using the device's date and time settings.
String locationTimestampLabel(BuildContext context, DateTime timestamp) {
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

/// Describes precise, approximate, or unknown permission accuracy.
String locationPrecisionLabel(LocationSnapshot snapshot) =>
    switch (snapshot.isApproximate) {
      true => TextConstants.approximateLocation,
      false => TextConstants.preciseLocation,
      null => TextConstants.unknownPrecision,
    };
