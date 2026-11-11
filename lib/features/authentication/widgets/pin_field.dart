import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/text_constants.dart';
import '../services/pin_service.dart';

class PinField extends StatefulWidget {
  const PinField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.onSubmitted,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      keyboardType: TextInputType.number,
      textInputAction: widget.onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      enableInteractiveSelection: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(PinService.pinLength),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _obscured = !_obscured)
              : null,
          tooltip: _obscured ? TextConstants.showPin : TextConstants.hidePin,
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}
