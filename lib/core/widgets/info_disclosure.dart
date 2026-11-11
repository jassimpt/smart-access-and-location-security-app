import 'package:flutter/material.dart';
import '../constants/text_constants.dart';

class InfoDisclosure extends StatelessWidget {
  const InfoDisclosure({required this.paragraphs, super.key});
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    dense: true,
    shape: const Border(),
    collapsedShape: const Border(),
    leading: const Icon(Icons.info_outline_rounded, size: 18),
    title: Text(
      TextConstants.howItWorks,
      style: Theme.of(context).textTheme.labelLarge,
    ),
    children: [
      for (final text in paragraphs)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
    ],
  );
}
