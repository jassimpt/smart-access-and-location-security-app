import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/text_constants.dart';
import '../../../core/widgets/app_page.dart';
import '../controllers/location_controller.dart';
import '../widgets/location_content.dart';
import '../../../core/widgets/section_header.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(locationControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationControllerProvider);
    return AppPage(
      children: [
        const SectionHeader(
          title: TextConstants.location,
          subtitle: TextConstants.locationSubtitle,
        ),
        LocationContent(state: state),
      ],
    );
  }
}
