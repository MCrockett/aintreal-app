import 'package:flutter/material.dart';

import '../../widgets/gradient_background.dart';

/// Results screen showing final rankings and scores.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
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
                'Results: $gameCode',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 32),
              const Expanded(
                child: Center(
                  child: Text(
                    'Results screen coming soon...',
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
