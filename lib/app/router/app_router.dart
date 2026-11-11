import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/text_constants.dart';
import '../../core/widgets/app_message.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/location/screens/location_screen.dart';
import '../../features/tracking/screens/tracking_screen.dart';
import '../../features/tracking/screens/tracking_history_screen.dart';
import '../../features/tracking/screens/tracking_session_screen.dart';
import '../widgets/app_shell.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.overview,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.overview,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.location,
                builder: (context, state) => const LocationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.tracking,
                builder: (context, state) => const TrackingScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const TrackingHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: ':sessionId',
                        builder: (context, state) => TrackingSessionScreen(
                          sessionId: state.pathParameters['sessionId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: AppMessage(
          title: TextConstants.pageNotFound,
          action: FilledButton(
            onPressed: () => context.go(RoutePaths.overview),
            child: const Text(TextConstants.backToOverview),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
