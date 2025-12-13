import 'package:flutter/material.dart';

import '../../widgets/gradient_background.dart';

/// Game screen for active gameplay with image selection.
class GameScreen extends StatelessWidget {
  const GameScreen({
    super.key,
    required this.gameCode,
  });

  final String gameCode;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Playing: $gameCode',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 32),
              const Expanded(
                child: Center(
                  child: Text(
                    'Game screen coming soon...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
