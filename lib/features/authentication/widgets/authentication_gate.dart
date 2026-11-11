import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/authentication_controller.dart';
import '../states/authentication_state.dart';
import 'authentication_view.dart';

class AuthenticationGate extends ConsumerStatefulWidget {
  const AuthenticationGate({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends ConsumerState<AuthenticationGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(authenticationControllerProvider.notifier).handleLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
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
                child: Offstage(offstage: !visible, child: widget.child),
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
