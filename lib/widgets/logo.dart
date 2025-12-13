import 'package:flutter/material.dart';

import '../config/theme.dart';

/// The AIn't Real logo widget with gradient text.
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.fontSize = 48,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
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
  }
}
