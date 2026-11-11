import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/tracking_controller.dart';
import '../controllers/tracking_export_controller.dart';
import '../models/tracking_export_format.dart';
import 'tracking_export_sheet.dart';

class ExportHistoryButton extends ConsumerWidget {
  const ExportHistoryButton({super.key});

  /// Offers a file format before preparing history and opening the native share sheet.
  Future<void> _chooseFormat(BuildContext context, WidgetRef ref) async {
    final format = await showModalBottomSheet<TrackingExportFormat>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const TrackingExportSheet(),
    );
    if (format == null || !context.mounted) return;
    final viewport = Offset.zero & MediaQuery.sizeOf(context);
    final box = context.findRenderObject();
    final bounds = box is RenderBox && box.attached && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size).intersect(viewport)
        : Rect.zero;
    final origin = bounds.isEmpty
        ? Rect.fromCenter(center: viewport.center, width: 1, height: 1)
        : bounds;
    await ref
        .read(trackingExportControllerProvider.notifier)
        .export(format, origin);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingControllerProvider);
    final exporting = ref.watch(
      trackingExportControllerProvider.select((state) => state.isExporting),
    );
    return FilledButton.tonalIcon(
      onPressed:
          exporting ||
              tracking.isBusy ||
              !tracking.initialized ||
              tracking.loadFailed ||
              tracking.history.isEmpty
          ? null
          : () => _chooseFormat(context, ref),
      icon: exporting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share_rounded),
      label: Text(
        exporting ? TextConstants.exportPreparing : TextConstants.exportHistory,
      ),
    );
  }
}
