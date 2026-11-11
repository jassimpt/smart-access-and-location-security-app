import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/authentication_controller.dart';
import '../helpers/security_display_helpers.dart';
import 'authentication_feedback.dart';
import 'auto_lock_options.dart';

class SecuritySettings extends ConsumerWidget {
  const SecuritySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authenticationControllerProvider).asData?.value;
    if (state?.record == null) return const SizedBox.shrink();
    final controller = ref.read(authenticationControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          TextConstants.security,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AuthenticationFeedback(message: state!.message),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: Icon(
                    Icons.fingerprint_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(TextConstants.biometricUnlock),
                  subtitle: Text(biometricDescription(state.capabilities)),
                  value: state.record!.biometricsEnabled,
                  onChanged:
                      state.isBusy ||
                          (!state.capabilities.canAuthenticate &&
                              !state.record!.biometricsEnabled)
                      ? null
                      : controller.setBiometricsEnabled,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : controller.refreshCapabilities,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(TextConstants.refreshSecurity),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text(TextConstants.pinProtected),
                  subtitle: Text(
                    TextConstants.securitySummary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text(TextConstants.lastAuthentication),
                  subtitle: Text(
                    lastAuthenticationLabel(
                      context,
                      state.record!.lastAuthenticatedAt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.isBusy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          if (state.isBiometricPrompt)
            TextButton(
              onPressed: controller.cancelBiometrics,
              child: const Text(TextConstants.cancelBiometrics),
            ),
        ],
        const SizedBox(height: 16),
        const AutoLockOptions(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : controller.lock,
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text(TextConstants.lockNow),
        ),
      ],
    );
  }
}
