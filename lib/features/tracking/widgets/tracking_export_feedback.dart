import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/tracking_export_controller.dart';

class TrackingExportFeedback extends ConsumerWidget {
  const TrackingExportFeedback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingExportControllerProvider);
    if (state.message == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          state.message!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: state.isError ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
