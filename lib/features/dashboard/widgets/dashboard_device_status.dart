import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../authentication/helpers/security_display_helpers.dart';
import '../../location/models/location_device_status.dart';
import '../controllers/dashboard_controller.dart';
import 'dashboard_status_row.dart';
import '../../../core/widgets/value_grid.dart';

class DashboardDeviceStatus extends ConsumerWidget {
  const DashboardDeviceStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (security, device) = ref.watch(
      dashboardSummaryProvider.select(
        (summary) => (summary.security, summary.location.device),
      ),
    );
    final capabilities = security?.capabilities;
    final biometrics = capabilities == null
        ? TextConstants.dashboardNotChecked
        : capabilities.checkFailed
        ? TextConstants.dashboardUnavailable
        : !capabilities.hasHardware
        ? TextConstants.dashboardBiometricNotSupported
        : capabilities.enrolledTypes.isEmpty
        ? TextConstants.dashboardBiometricNotEnrolled
        : security!.record?.biometricsEnabled == true
        ? TextConstants.dashboardEnabled
        : TextConstants.dashboardDisabled;
    final permission = switch (device?.permission) {
      LocationPermissionStatus.granted => TextConstants.dashboardGranted,
      LocationPermissionStatus.permanentlyDenied =>
        TextConstants.dashboardBlocked,
      LocationPermissionStatus.denied => TextConstants.dashboardNotGranted,
      null => TextConstants.dashboardNotChecked,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              TextConstants.dashboardDeviceStatus,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (security?.record != null)
              const Text(TextConstants.pinProtected),
            const SizedBox(height: 16),
            ValueGrid(
              minimumWidth: 120,
              children: [
                DashboardStatusRow(
                  icon: Icons.fingerprint_rounded,
                  label: TextConstants.dashboardBiometrics,
                  value: biometrics,
                  detail: capabilities == null
                      ? null
                      : biometricDescription(capabilities),
                ),
                DashboardStatusRow(
                  icon: Icons.location_on_outlined,
                  label: TextConstants.dashboardPermission,
                  value: permission,
                ),
                DashboardStatusRow(
                  icon: Icons.gps_fixed_rounded,
                  label: TextConstants.dashboardGps,
                  value: device == null
                      ? TextConstants.dashboardNotChecked
                      : device.serviceEnabled
                      ? TextConstants.dashboardEnabled
                      : TextConstants.dashboardDisabled,
                ),
              ],
            ),
            const Divider(),
            DashboardStatusRow(
              icon: Icons.verified_user_outlined,
              label: TextConstants.lastAuthentication,
              value: lastAuthenticationLabel(
                context,
                security?.record?.lastAuthenticatedAt,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.go(RoutePaths.settings),
                icon: const Icon(Icons.settings_outlined),
                label: const Text(TextConstants.dashboardSecuritySettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
