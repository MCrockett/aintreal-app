import 'package:flutter/material.dart';

import '../../widgets/gradient_background.dart';

/// Lobby screen showing players and game configuration.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
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
                'Game: $gameCode',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 32),
              const Expanded(
                child: Center(
                  child: Text(
                    'Lobby coming soon...',
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
