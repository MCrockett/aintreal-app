import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_provider.dart';

/// Provider for user stats from the backend API.
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final authState = ref.watch(authProvider);

  // If not authenticated, return empty stats
  if (authState is! AuthStateAuthenticated) {
    return UserStats(
      party: const PartyStats(games: 0, wins: 0, correct: 0, answered: 0),
      solo: const SoloStats(games: 0, correct: 0, answered: 0),
      marathon: const MarathonStats(attempts: 0, correct: 0, bestStreak: 0, perfectRuns: 0),
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
    return profile.stats;
  } catch (e) {
    debugPrint('Failed to fetch user stats: $e');
    rethrow;
  }
});

/// Card displaying user game statistics by mode.
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

    return Column(
      children: [
        statsAsync.when(
          data: (stats) => _buildStats(context, stats, isGuest, onSignIn),
          loading: () => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
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
      ],
    );
  }

  Widget _buildStats(BuildContext context, UserStats stats, bool isGuest, VoidCallback? onSignIn) {
    final hasAnyGames = stats.party.games > 0 || stats.solo.games > 0 || stats.marathon.attempts > 0;

    return Column(
      children: [
        // Party Mode Section
        _ModeStatsCard(
          title: 'Party Mode',
          icon: Icons.groups,
          iconColor: AppTheme.primary,
          isEmpty: stats.party.games == 0,
          children: [
            _StatRow(
              items: [
                _StatItem(label: 'Games', value: stats.party.games.toString()),
                _StatItem(label: 'Wins', value: stats.party.wins.toString(), color: AppTheme.warning),
                _StatItem(label: 'Win Rate', value: '${stats.party.winRate.toStringAsFixed(0)}%', color: AppTheme.success),
              ],
            ),
            if (stats.party.answered > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Accuracy: ${stats.party.correct}/${stats.party.answered} (${stats.party.accuracy.toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Solo Practice Section
        _ModeStatsCard(
          title: 'Solo Practice',
          icon: Icons.person,
          iconColor: AppTheme.textSecondary,
          isEmpty: stats.solo.games == 0,
          children: [
            _StatRow(
              items: [
                _StatItem(label: 'Sessions', value: stats.solo.games.toString()),
                _StatItem(label: 'Correct', value: stats.solo.correct.toString(), color: AppTheme.success),
                _StatItem(label: 'Accuracy', value: '${stats.solo.accuracy.toStringAsFixed(0)}%', color: AppTheme.primary),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Marathon Section
        _ModeStatsCard(
          title: 'Marathon',
          icon: Icons.emoji_events,
          iconColor: AppTheme.bonusStreak,
          isEmpty: stats.marathon.attempts == 0,
          children: [
            _StatRow(
              items: [
                _StatItem(label: 'Attempts', value: stats.marathon.attempts.toString()),
                _StatItem(label: 'Best Streak', value: '${stats.marathon.bestStreak}/26', color: AppTheme.bonusStreak),
                _StatItem(label: 'Perfect', value: stats.marathon.perfectRuns.toString(), color: AppTheme.warning),
              ],
            ),
          ],
        ),

        // Guest message
        if (isGuest) ...[
          const SizedBox(height: 16),
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
                    Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
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
                  kIsWeb
                      ? 'Stats are not saved for guest sessions. Download the app to sign in!'
                      : 'Sign in to save your stats and play across devices.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => launchUrl(Uri.parse('https://aint-real.com')),
                      child: const Text('Get the App'),
                    ),
                  ),
                ] else if (onSignIn != null) ...[
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
          ),
        ],

        // Empty stats message
        if (!hasAnyGames && !isGuest) ...[
          const SizedBox(height: 16),
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

/// Card for a single game mode's stats.
class _ModeStatsCard extends StatelessWidget {
  const _ModeStatsCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isEmpty,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            Text(
              'No games yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

/// Row of stat items.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) => Expanded(child: item)).toList(),
    );
  }
}

/// Individual stat item.
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}
