import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/location_controller.dart';
import '../widgets/location_content.dart';
import '../widgets/location_status_card.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(locationControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(locationControllerProvider.notifier).handleLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationControllerProvider);
    final theme = Theme.of(context);
    return AppPage(
      children: [
        Text(TextConstants.location, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          TextConstants.locationPageDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        const LocationStatusCard(),
        if (state.snapshot != null) ...[
          const SizedBox(height: 20),
          LocationContent(state: state),
        ],
      ],
    );
  }
}
