import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../authentication/controllers/authentication_controller.dart';
import '../../authentication/states/authentication_state.dart';
import '../../geofencing/controllers/geofence_controller.dart';
import '../../location/controllers/location_controller.dart';
import '../../tracking/controllers/tracking_controller.dart';
import '../models/dashboard_summary.dart';
import '../states/dashboard_state.dart';

final dashboardSummaryProvider = Provider(
  (ref) => DashboardSummary(
    security: ref.watch(authenticationControllerProvider).asData?.value,
    location: ref.watch(locationControllerProvider),
    tracking: ref.watch(trackingControllerProvider),
    areas: ref.watch(geofenceControllerProvider),
  ),
);
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  bool _enabled = false;
  bool _foreground = true;

  bool get _canRead {
    final security = ref.read(authenticationControllerProvider).asData?.value;
    return _foreground &&
        security?.status == AuthenticationStatus.unlocked &&
        !security!.isObscured;
  }

  @override
  DashboardState build() {
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (_enabled &&
          previous?.asData?.value.status != AuthenticationStatus.unlocked &&
          next.asData?.value.status == AuthenticationStatus.unlocked) {
        unawaited(refresh());
      }
    });
    return const DashboardState();
  }

  /// Enables dashboard restoration after unlock without prompting for permissions.
  Future<void> initialize() async {
    _enabled = true;
    if (_canRead) await refresh();
  }

  /// Restores feature summaries and checks device status without starting tracking or geofencing.
  Future<void> refresh() async {
    if (!_canRead || state.isRefreshing) return;
    state = DashboardState(isRefreshing: true, checkedAt: state.checkedAt);
    try {
      await Future.wait<void>([
        ref
            .read(authenticationControllerProvider.notifier)
            .refreshCapabilities(),
        ref.read(locationControllerProvider.notifier).refresh(),
        ref.read(trackingControllerProvider.notifier).initialize(),
        ref.read(geofenceControllerProvider.notifier).initialize(),
      ]);
      if (ref.mounted) {
        state = DashboardState(checkedAt: DateTime.now().toUtc());
      }
    } catch (_) {
      if (ref.mounted) {
        state = DashboardState(
          checkedAt: state.checkedAt,
          message: TextConstants.dashboardRefreshFailed,
        );
      }
    }
  }

  /// Refreshes status after returning from system settings while keeping locked data hidden.
  void handleLifecycle(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      _foreground = false;
    } else if (lifecycle == AppLifecycleState.resumed) {
      _foreground = true;
      if (_enabled) unawaited(refresh());
    }
  }
}
