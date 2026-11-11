import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/text_constants.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Opens a destination while retaining each branch's navigation state.
  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;
        return Scaffold(
          appBar: AppBar(
            title: const Text(TextConstants.appName),
            leading: Icon(
              Icons.shield_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          body: Row(
            children: [
              if (useRail) ...[
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _selectDestination,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.grid_view_outlined),
                        selectedIcon: Icon(Icons.grid_view_rounded),
                        label: Text(TextConstants.overview),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text(TextConstants.settings),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: navigationShell),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: TextConstants.overview,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: TextConstants.settings,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
