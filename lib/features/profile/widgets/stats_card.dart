import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_provider.dart';

/// Provider for user stats from the backend API.
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final authState = ref.watch(authProvider);

  // If not authenticated, return empty stats
  if (authState is! AuthStateAuthenticated) {
    return const UserStats(
      gamesPlayed: 0,
      gamesWon: 0,
      totalCorrect: 0,
      totalAnswered: 0,
      bestMarathonStreak: 0,
      perfectMarathons: 0,
    );
  }

  try {
    // Get fresh ID token
    final idToken = await authState.user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get ID token');
    }

    // Fetch profile from backend
    final profile = await AuthApi.instance.getProfile(idToken);
    return UserStats(
      gamesPlayed: profile.stats.gamesPlayed,
      gamesWon: profile.stats.gamesWon,
      totalCorrect: profile.stats.totalCorrect,
      totalAnswered: profile.stats.totalAnswered,
      bestMarathonStreak: profile.stats.bestMarathonStreak,
      perfectMarathons: profile.stats.perfectMarathons,
    );
  } catch (e) {
    // Return empty stats on error
    debugPrint('Failed to fetch user stats: $e');
    return const UserStats(
      gamesPlayed: 0,
      gamesWon: 0,
      totalCorrect: 0,
      totalAnswered: 0,
      bestMarathonStreak: 0,
      perfectMarathons: 0,
    );
  }
});

/// User statistics model.
class UserStats {
  const UserStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.totalCorrect,
    required this.totalAnswered,
    required this.bestMarathonStreak,
    required this.perfectMarathons,
  });

  final int gamesPlayed;
  final int gamesWon;
  final int totalCorrect;
  final int totalAnswered;
  final int bestMarathonStreak;
  final int perfectMarathons;

  double get accuracy =>
      totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0;

  double get winRate =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;
}

/// Card displaying user game statistics.
class StatsCard extends ConsumerWidget {
  const StatsCard({
    super.key,
    this.isGuest = false,
    this.onSignIn,
  });

  final bool isGuest;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) => _buildStats(context, stats, isGuest, onSignIn),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load stats',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, UserStats stats, bool isGuest, VoidCallback? onSignIn) {
    return Column(
      children: [
        // Main stats row
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Games',
                value: stats.gamesPlayed.toString(),
                icon: Icons.games,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Wins',
                value: stats.gamesWon.toString(),
                icon: Icons.emoji_events,
                iconColor: AppTheme.warning,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Win Rate',
                value: '${stats.winRate.toStringAsFixed(0)}%',
                icon: Icons.trending_up,
                iconColor: AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // Accuracy stats
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Correct',
                value: stats.totalCorrect.toString(),
                icon: Icons.check_circle,
                iconColor: AppTheme.success,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Answered',
                value: stats.totalAnswered.toString(),
                icon: Icons.touch_app,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Accuracy',
                value: '${stats.accuracy.toStringAsFixed(0)}%',
                icon: Icons.gps_fixed,
                iconColor: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // Marathon stats
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Best Streak',
                value: '${stats.bestMarathonStreak}/26',
                icon: Icons.local_fire_department,
                iconColor: AppTheme.bonusStreak,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Perfect Runs',
                value: stats.perfectMarathons.toString(),
                icon: Icons.star,
                iconColor: AppTheme.warning,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        // Message for empty stats
        if (stats.gamesPlayed == 0) ...[
          const SizedBox(height: 20),
          if (isGuest)
            // Guest sign-in prompt
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Playing as Guest',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to save your stats and play across devices.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (onSignIn != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSignIn,
                        child: const Text('Sign In'),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Play some games to see your stats!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Individual stat item widget.
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
