import 'package:flutter/material.dart';

import '../config/theme.dart';

/// A widget that provides the app's gradient background.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: child,
      ),
    );
  }
}
