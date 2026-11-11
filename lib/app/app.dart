import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/text_constants.dart';
import 'bootstrap.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/startup_screen.dart';

class SmartAccess extends ConsumerWidget {
  const SmartAccess({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(appInitializationProvider);
    if (!initialization.hasValue) {
      return MaterialApp(
        title: TextConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: StartupScreen(hasError: initialization.hasError),
      );
    }
    final theme = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: TextConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
