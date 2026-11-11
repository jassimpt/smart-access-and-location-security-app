import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../widgets/authentication_layout.dart';
import '../widgets/pin_setup_form.dart';

class PinSetupScreen extends StatelessWidget {
  const PinSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthenticationLayout(
    title: TextConstants.setupPinTitle,
    description: TextConstants.setupPinDescription,
    child: PinSetupForm(),
  );
}
