import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/tracking_controller.dart';
import 'tracking_history_tile.dart';

class TrackingHistoryList extends ConsumerWidget {
  const TrackingHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    if (!state.initialized && !state.loadFailed) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadFailed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(TextConstants.trackingLoadFailed),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.isBusy
                    ? null
                    : ref.read(trackingControllerProvider.notifier).initialize,
                child: const Text(TextConstants.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (state.history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.route_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 20),
              Text(
                TextConstants.historyEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(TextConstants.historyEmptyDescription),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in state.history) ...[
          TrackingHistoryTile(session: session),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
