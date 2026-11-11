import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../location/widgets/location_notice.dart';
import '../controllers/dashboard_controller.dart';

class DashboardRefreshControls extends ConsumerWidget {
  const DashboardRefreshControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final partialFailure = ref.watch(
      dashboardSummaryProvider.select((summary) => summary.hasStorageFailure),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: state.isRefreshing
                ? null
                : ref.read(dashboardControllerProvider.notifier).refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(TextConstants.dashboardRefresh),
          ),
        ),
        if (state.isRefreshing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (state.message != null) LocationNotice(message: state.message!),
        if (partialFailure)
          const LocationNotice(message: TextConstants.dashboardPartialFailure),
      ],
    );
  }
}
