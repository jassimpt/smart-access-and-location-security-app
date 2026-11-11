import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/text_constants.dart';
import '../../core/widgets/app_message.dart';
import '../bootstrap.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({this.hasError = false, super.key});

  final bool hasError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: hasError
            ? AppMessage(
                title: TextConstants.startupErrorTitle,
                description: TextConstants.startupErrorDescription,
                icon: Icons.storage_rounded,
                action: FilledButton(
                  onPressed: () => ref.invalidate(appInitializationProvider),
                  child: const Text(TextConstants.retry),
                ),
              )
            : const AppMessage(
                title: TextConstants.startingApp,
                icon: Icons.shield_outlined,
                action: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
