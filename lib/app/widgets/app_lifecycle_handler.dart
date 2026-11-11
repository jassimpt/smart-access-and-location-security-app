import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/controllers/authentication_controller.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/geofencing/controllers/geofence_controller.dart';
import '../../features/location/controllers/location_controller.dart';
import '../../features/tracking/controllers/tracking_controller.dart';

class AppLifecycleHandler extends ConsumerStatefulWidget {
  const AppLifecycleHandler({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
        didChangeAppLifecycleState(lifecycle);
      }
      ref.read(dashboardControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(authenticationControllerProvider.notifier).handleLifecycle(state);
    ref.read(locationControllerProvider.notifier).handleLifecycle(state);
    ref.read(trackingControllerProvider.notifier).handleLifecycle(state);
    ref.read(geofenceControllerProvider.notifier).handleLifecycle(state);
    ref.read(dashboardControllerProvider.notifier).handleLifecycle(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
