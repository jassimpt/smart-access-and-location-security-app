import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track_point.dart';

final trackingMetricsServiceProvider = Provider(
  (ref) => TrackingMetricsService(),
);

class TrackingMetricsService {
  /// Rejects poor GPS fixes, duplicate timestamps, drift, and implausible jumps.
  ({bool accepted, double distance, double speed}) evaluate(
    TrackPoint? previous,
    TrackPoint point,
  ) {
    if (point.accuracy > 75) return (accepted: false, distance: 0, speed: 0);
    if (previous == null || previous.segment != point.segment) {
      return (accepted: true, distance: 0, speed: 0);
    }
    final seconds =
        point.recordedAt.difference(previous.recordedAt).inMilliseconds / 1000;
    if (seconds <= 0) return (accepted: false, distance: 0, speed: 0);
    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      point.latitude,
      point.longitude,
    );
    final threshold = math.max(
      3.0,
      math.min(previous.accuracy, point.accuracy) / 2,
    );
    if (distance < threshold || distance / seconds > 100) {
      return (accepted: false, distance: 0, speed: 0);
    }
    final speed = point.speed > 0 && point.speed <= 100
        ? point.speed
        : distance / seconds;
    return (accepted: true, distance: distance, speed: speed);
  }
}
