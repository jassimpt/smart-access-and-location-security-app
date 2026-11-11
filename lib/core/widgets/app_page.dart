import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  const AppPage({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
