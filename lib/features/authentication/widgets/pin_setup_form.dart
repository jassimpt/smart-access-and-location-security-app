import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../controllers/authentication_controller.dart';
import '../services/pin_service.dart';
import 'authentication_feedback.dart';
import 'pin_field.dart';

class PinSetupForm extends ConsumerStatefulWidget {
  const PinSetupForm({super.key});

  @override
  ConsumerState<PinSetupForm> createState() => _PinSetupFormState();
}

class _PinSetupFormState extends ConsumerState<PinSetupForm> {
  final _form = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  /// Validates both fields before creating the secure PIN.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authenticationControllerProvider.notifier)
        .createPin(_pin.text, _confirmation.text);
    if (mounted) {
      _pin.clear();
      _confirmation.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authenticationControllerProvider).requireValue;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthenticationFeedback(message: state.message),
          PinField(
            controller: _pin,
            label: TextConstants.pinLabel,
            enabled: !state.isBusy,
            validator: (value) =>
                ref.read(pinServiceProvider).isValid(value ?? '')
                ? null
                : TextConstants.invalidPin,
          ),
          const SizedBox(height: 20),
          PinField(
            controller: _confirmation,
            label: TextConstants.confirmPinLabel,
            enabled: !state.isBusy,
            validator: (value) =>
                value == _pin.text ? null : TextConstants.pinMismatch,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Text(
            TextConstants.pinHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isBusy ? null : _submit,
            child: const Text(TextConstants.createPin),
          ),
          if (state.isBusy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
