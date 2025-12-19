import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/game.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/how_to_play_dialog.dart';
import '../../widgets/logo.dart';

/// Home screen with game mode selection.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Logo(),
              const SizedBox(height: 8),
              Text(
                'Spot the AI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const Spacer(flex: 2),

              // Mode selection cards
              _ModeCard(
                mode: GameMode.party,
                title: 'Party Mode',
                subtitle: '2-8 players',
                description: 'Play with friends! Everyone guesses at once.',
                icon: Icons.groups,
                onTap: () => context.push(
                  AppRoutes.createGame,
                  extra: {'mode': GameMode.party},
                ),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                mode: GameMode.classic,
                title: 'Classic Solo',
                subtitle: 'Single player',
                description: 'Practice at your own pace.',
                icon: Icons.person,
                onTap: () => context.push(
                  AppRoutes.createGame,
                  extra: {'mode': GameMode.classic},
                ),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                mode: GameMode.marathon,
                title: 'Marathon',
                subtitle: '26 rounds',
                description: 'How far can you go? One miss and it\'s over!',
                icon: Icons.emoji_events,
                onTap: () => context.push(
                  AppRoutes.createGame,
                  extra: {'mode': GameMode.marathon},
                ),
              ),

              const SizedBox(height: 24),

              // Join game button
              _HomeButton(
                label: 'Join Game',
                subtitle: 'Enter code',
                onPressed: () => context.push(AppRoutes.joinGame),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => showHowToPlayDialog(context),
                child: const Text('How to Play'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mode selection card widget.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final GameMode mode;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isParty = mode == GameMode.party;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isParty ? AppTheme.primaryGradient : null,
        color: isParty ? null : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: isParty
            ? null
            : Border.all(color: AppTheme.secondary, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isParty
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isParty ? Colors.white : AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isParty ? Colors.white : AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isParty
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppTheme.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: isParty
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: isParty
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: isParty
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          side: BorderSide.none,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
