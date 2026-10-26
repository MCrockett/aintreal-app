import 'package:flutter/material.dart';


/// The AIn't Real logo widget with optional icon and styled text.
/// Dark "AI" and a coral gradient on "n't Real" (spec D7).
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
    // scaleDown: shrink rather than overflow on narrow screens or large
    // accessibility text sizes; never scales up past fontSize.
    final textWidget = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Matches the Reddit splash and the website: dark "AI", coral
          // gradient on "n't Real"
          Text(
            'AI',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB02E45),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8A8A)],
            ).createShader(bounds),
            child: Text(
              "n't Real",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
