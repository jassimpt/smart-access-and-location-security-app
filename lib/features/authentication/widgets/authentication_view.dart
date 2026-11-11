import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_message.dart';
import '../controllers/authentication_controller.dart';
import '../screens/pin_setup_screen.dart';
import '../screens/unlock_screen.dart';
import '../states/authentication_state.dart';

class AuthenticationView extends ConsumerWidget {
  const AuthenticationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authentication = ref.watch(authenticationControllerProvider);
    return PopScope(
      canPop: false,
      child: authentication.when(
        loading: () => const Scaffold(
          body: SafeArea(
            child: AppMessage(
              title: TextConstants.authenticationLoading,
              icon: Icons.shield_outlined,
              action: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: SafeArea(
            child: AppMessage(
              title: TextConstants.authenticationErrorTitle,
              description: TextConstants.authenticationLoadError,
              action: FilledButton(
                onPressed: () =>
                    ref.invalidate(authenticationControllerProvider),
                child: const Text(TextConstants.retry),
              ),
            ),
          ),
        ),
        data: (state) => state.isObscured
            ? const Scaffold(
                body: SafeArea(
                  child: AppMessage(
                    title: TextConstants.appName,
                    icon: Icons.shield_outlined,
                  ),
                ),
              )
            : state.status == AuthenticationStatus.setupRequired
            ? const PinSetupScreen()
            : const UnlockScreen(),
      ),
    );
  }
}
