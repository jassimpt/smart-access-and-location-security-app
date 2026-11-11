import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';
import '../widgets/authentication_layout.dart';
import '../widgets/pin_unlock_form.dart';

class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthenticationLayout(
    title: TextConstants.unlockTitle,
    description: TextConstants.unlockDescription,
    child: PinUnlockForm(),
  );
}
