import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/tracking_controller.dart';
import '../controllers/tracking_export_controller.dart';
import 'clear_tracking_history_dialog.dart';

class ClearHistoryButton extends ConsumerWidget {
  const ClearHistoryButton({super.key});

  /// Requests confirmation before deleting completed history from local storage.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ClearTrackingHistoryDialog(),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(trackingControllerProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    final exporting = ref.watch(
      trackingExportControllerProvider.select((state) => state.isExporting),
    );
    return OutlinedButton.icon(
      onPressed: state.isBusy || exporting || state.history.isEmpty
          ? null
          : () => _confirm(context, ref),
      icon: const Icon(Icons.delete_outline_rounded),
      label: const Text(TextConstants.clearHistory),
    );
  }
}
