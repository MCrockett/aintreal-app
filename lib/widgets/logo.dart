import 'package:flutter/material.dart';

import '../config/theme.dart';

/// The AIn't Real logo widget with optional icon and gradient text.
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
    final textWidget = ShaderMask(
      shaderCallback: (bounds) => AppTheme.logoGradient.createShader(bounds),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          children: [
            // "A" with AI gradient
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.aiHighlightGradient.createShader(bounds),
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const TextSpan(text: "n't Real"),
          ],
        ),
      ),
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
