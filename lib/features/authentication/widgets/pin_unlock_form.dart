import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/authentication_controller.dart';
import '../services/pin_service.dart';
import 'authentication_feedback.dart';
import 'pin_field.dart';

class PinUnlockForm extends ConsumerStatefulWidget {
  const PinUnlockForm({super.key});

  @override
  ConsumerState<PinUnlockForm> createState() => _PinUnlockFormState();
}

class _PinUnlockFormState extends ConsumerState<PinUnlockForm> {
  final _form = GlobalKey<FormState>();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  /// Submits the PIN and clears it after each attempt.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authenticationControllerProvider.notifier)
        .unlockWithPin(_pin.text);
    if (mounted) _pin.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authenticationControllerProvider).requireValue;
    final controller = ref.read(authenticationControllerProvider.notifier);
    final lockedOut = controller.isPinLockedOut;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthenticationFeedback(
            message:
                state.message ?? (lockedOut ? TextConstants.pinLockout : null),
          ),
          PinField(
            controller: _pin,
            label: TextConstants.pinLabel,
            enabled: !state.isBusy && !lockedOut,
            validator: (value) =>
                ref.read(pinServiceProvider).isValid(value ?? '')
                ? null
                : TextConstants.invalidPin,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isBusy || lockedOut ? null : _submit,
            child: const Text(TextConstants.unlock),
          ),
          if (state.record!.biometricsEnabled &&
              state.capabilities.canAuthenticate) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.isBusy ? null : controller.unlockWithBiometrics,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text(TextConstants.useBiometrics),
            ),
          ],
          if (state.isBusy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            if (state.isBiometricPrompt)
              TextButton(
                onPressed: controller.cancelBiometrics,
                child: const Text(TextConstants.cancelBiometrics),
              ),
          ],
        ],
      ),
    );
  }
}
