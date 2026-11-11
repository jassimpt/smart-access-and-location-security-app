import 'package:flutter/material.dart';

import '../states/location_state.dart';
import 'location_details_card.dart';
import 'location_map.dart';

class LocationContent extends StatelessWidget {
  const LocationContent({required this.state, super.key});
  final LocationState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 800) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: LocationMap(snapshot: state.snapshot!)),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: LocationDetailsCard(state: state)),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationMap(snapshot: state.snapshot!),
          const SizedBox(height: 20),
          LocationDetailsCard(state: state),
        ],
      );
    },
  );
}
