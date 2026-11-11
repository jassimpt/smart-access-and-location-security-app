import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/authentication_controller.dart';
import '../helpers/security_display_helpers.dart';
import '../models/auto_lock_duration.dart';

class AutoLockOptions extends ConsumerWidget {
  const AutoLockOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authenticationControllerProvider).requireValue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              TextConstants.autoLock,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              TextConstants.autoLockDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AutoLockDuration.values
                  .map(
                    (duration) => ChoiceChip(
                      label: Text(autoLockLabel(duration)),
                      selected: state.record!.autoLock == duration,
                      onSelected: state.isBusy
                          ? null
                          : (selected) {
                              if (selected) {
                                ref
                                    .read(
                                      authenticationControllerProvider.notifier,
                                    )
                                    .setAutoLock(duration);
                              }
                            },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
