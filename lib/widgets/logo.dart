import 'package:flutter/material.dart';

import '../config/theme.dart';

/// The AIn't Real logo widget with optional icon and styled text.
/// "AI" is rendered in a monospace/console font with gradient.
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.fontSize = 48,
    this.showIcon = false,
    this.iconSize = 100,
  });

  final double fontSize;
  final bool showIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final textWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // "AI" in monospace with coral gradient
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.aiHighlightGradient.createShader(bounds),
          child: Text(
            'AI',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Courier New', 'Courier'],
              color: Colors.white,
            ),
          ),
        ),
        // "n't Real" in regular font
        Text(
          "n't Real",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );

    if (!showIcon) return textWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/app_icon.png',
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(height: 16),
        textWidget,
      ],
    );
  }
}
