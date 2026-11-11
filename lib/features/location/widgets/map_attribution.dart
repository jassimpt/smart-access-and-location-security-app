import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/text_constants.dart';
import '../constants/map_constants.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  /// Opens the map data attribution and licence page.
  Future<void> _openAttribution(BuildContext context) async {
    try {
      final opened = await launchUrl(
        Uri.parse(MapConstants.attributionUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(TextConstants.mapAttributionLinkFailed)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(TextConstants.mapAttributionLinkFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: TextButton(
      style: TextButton.styleFrom(
        textStyle: Theme.of(context).textTheme.labelSmall,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _openAttribution(context),
      child: const Text(TextConstants.mapAttribution, textAlign: TextAlign.end),
    ),
  );
}
