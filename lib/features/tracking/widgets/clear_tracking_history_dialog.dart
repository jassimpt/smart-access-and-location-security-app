import 'package:flutter/material.dart';

import '../../../core/constants/text_constants.dart';

class ClearTrackingHistoryDialog extends StatelessWidget {
  const ClearTrackingHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(TextConstants.clearTrackingHistoryTitle),
    content: const Text(TextConstants.clearTrackingHistoryDescription),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text(TextConstants.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text(TextConstants.clearHistory),
      ),
    ],
  );
}
