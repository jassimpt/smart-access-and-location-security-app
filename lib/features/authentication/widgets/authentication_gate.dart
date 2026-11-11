import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/authentication_controller.dart';
import '../states/authentication_state.dart';
import 'authentication_view.dart';

class AuthenticationGate extends ConsumerWidget {
  const AuthenticationGate({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authentication = ref.watch(authenticationControllerProvider);
    final state = authentication.asData?.value;
    final visible =
        state?.status == AuthenticationStatus.unlocked && !state!.isObscured;
    return Listener(
      onPointerDown: (_) => ref
          .read(authenticationControllerProvider.notifier)
          .recordInteraction(),
      onPointerMove: (_) => ref
          .read(authenticationControllerProvider.notifier)
          .recordInteraction(),
      onPointerSignal: (_) => ref
          .read(authenticationControllerProvider.notifier)
          .recordInteraction(),
      child: Focus(
        onKeyEvent: (node, event) {
          ref
              .read(authenticationControllerProvider.notifier)
              .recordInteraction();
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              excluding: !visible,
              child: TickerMode(
                enabled: visible,
                child: Offstage(offstage: !visible, child: child),
              ),
            ),
            if (!visible)
              HeroControllerScope.none(
                child: Navigator(
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (context) => const AuthenticationView(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
