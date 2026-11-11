import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/text_constants.dart';
import '../../authentication/controllers/authentication_controller.dart';
import '../../authentication/states/authentication_state.dart';
import '../models/tracking_export_format.dart';
import '../services/tracking_export_service.dart';
import '../states/tracking_export_state.dart';
import 'tracking_controller.dart';

final trackingExportControllerProvider =
    NotifierProvider<TrackingExportController, TrackingExportState>(
      TrackingExportController.new,
    );

class TrackingExportController extends Notifier<TrackingExportState> {
  @override
  TrackingExportState build() => const TrackingExportState();

  bool get _canShare {
    final security = ref.read(authenticationControllerProvider).asData?.value;
    return security?.status == AuthenticationStatus.unlocked &&
        !security!.isObscured;
  }

  /// Exports a stable history snapshot once and reports native sharing outcomes accurately.
  Future<void> export(TrackingExportFormat format, Rect origin) async {
    if (state.isExporting || !_canShare) return;
    final tracking = ref.read(trackingControllerProvider);
    if (!tracking.initialized ||
        tracking.isBusy ||
        tracking.loadFailed ||
        tracking.history.isEmpty) {
      return;
    }
    state = const TrackingExportState(isExporting: true);
    final service = ref.read(trackingExportServiceProvider);
    try {
      final file = await service.prepare(
        List.unmodifiable(tracking.history),
        format,
      );
      if (!ref.mounted || !_canShare) {
        await service.discard(file);
        return;
      }
      final result = await service.share(file, format, origin);
      if (!ref.mounted) return;
      state = TrackingExportState(
        message: switch (result) {
          ShareResultStatus.success => TextConstants.exportShared,
          ShareResultStatus.dismissed => TextConstants.exportCancelled,
          ShareResultStatus.unavailable => TextConstants.exportOpened,
        },
      );
    } catch (_) {
      if (ref.mounted) {
        state = const TrackingExportState(
          message: TextConstants.exportFailed,
          isError: true,
        );
      }
    } finally {
      if (ref.mounted && state.isExporting) state = const TrackingExportState();
    }
  }
}
