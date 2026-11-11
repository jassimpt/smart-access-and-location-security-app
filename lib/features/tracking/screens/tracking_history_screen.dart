import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../../location/widgets/location_notice.dart';
import '../controllers/tracking_controller.dart';
import '../widgets/clear_history_button.dart';
import '../widgets/export_history_button.dart';
import '../widgets/tracking_export_feedback.dart';
import '../widgets/tracking_history_list.dart';
import '../widgets/tracking_history_summary.dart';
import '../../../core/widgets/section_header.dart';

class TrackingHistoryScreen extends ConsumerWidget {
  const TrackingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    return AppPage(
      children: [
        const SectionHeader(
          title: TextConstants.trackingHistory,
          subtitle: TextConstants.savedJourneys,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton.icon(
              onPressed: () => context.go(RoutePaths.tracking),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(TextConstants.backToTracking),
            ),
            const ExportHistoryButton(),
            const ClearHistoryButton(),
          ],
        ),
        const TrackingExportFeedback(),
        if (state.message != null) LocationNotice(message: state.message!),
        const SizedBox(height: 20),
        const TrackingHistorySummary(),
        const SizedBox(height: 16),
        const TrackingHistoryList(),
      ],
    );
  }
}
