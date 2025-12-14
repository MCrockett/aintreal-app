import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/audio/sound_service.dart';
import '../../core/websocket/game_state_provider.dart';
import '../../core/websocket/ws_messages.dart';
import '../../widgets/gradient_background.dart';

/// Results screen showing final rankings and scores.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({
    super.key,
    required this.gameCode,
  });

  final String gameCode;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late ConfettiController _confettiController;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // Start confetti after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  void _playGameEndSound(bool isWinner) {
    if (!_soundPlayed) {
      _soundPlayed = true;
      // Delay slightly to sync with screen transition
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isWinner) {
          SoundService.instance.playVictory();
        } else {
          SoundService.instance.playGameOver();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playAgain() {
    ref.read(gameStateProvider.notifier).playAgain();
  }

  void _newGame() {
    ref.read(gameStateProvider.notifier).leave();
    context.go('/');
  }

  void _leaveGame() {
    ref.read(gameStateProvider.notifier).leave();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final gameOverData = gameState.gameOverData;
    final isHost = gameState.isHost;
    final playerId = gameState.playerId;

    // Listen for return to lobby
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (next.status == GameStatus.lobby) {
        context.go('/lobby/${widget.gameCode}', extra: {
          'playerName': next.playerName,
          'playerId': next.playerId,
          'isHost': next.isHost,
          'config': next.config != null
              ? {
                  'rounds': next.config!.rounds,
                  'timePerRound': next.config!.timePerRound,
                  'speedBonus': next.config!.speedBonus,
                  'randomBonuses': next.config!.randomBonuses,
                  'mode': next.config!.mode,
                }
              : null,
        });
      }
    });

    // Handle no game over data
    if (gameOverData == null) {
      return GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading results...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rankings = gameOverData.rankings;
    final totalRounds = gameOverData.totalRounds;

    // Find current player's rank
    final myRanking = rankings.cast<FinalRanking?>().firstWhere(
          (r) => r?.playerId == playerId,
          orElse: () => null,
        );
    final isWinner = myRanking?.rank == 1;

    // Play victory or game over sound
    _playGameEndSound(isWinner);

    return GradientBackground(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // Balance
                      Text(
                        'Game Over!',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _leaveGame,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Winner announcement
                if (rankings.isNotEmpty) _WinnerBanner(winner: rankings.first),

                const SizedBox(height: 24),

                // Rankings list
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Final Standings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '$totalRounds rounds',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _RankingsList(
                            rankings: rankings,
                            currentPlayerId: playerId,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (isHost) ...[
                        // Play Again button (host only)
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _playAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text('Play Again'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // New Game button
                        OutlinedButton(
                          onPressed: _newGame,
                          child: const Text('New Game'),
                        ),
                      ] else ...[
                        // Non-host waiting message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppTheme.secondary, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Waiting for host to start next game...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Leave button (non-host)
                        OutlinedButton(
                          onPressed: _leaveGame,
                          child: const Text('Leave Game'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti overlay for winner
          if (isWinner)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppTheme.primary,
                  AppTheme.primaryLight,
                  AppTheme.bonusRank,
                  AppTheme.correctAnswer,
                  Colors.white,
                ],
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                gravity: 0.3,
              ),
            ),
        ],
      ),
    );
  }
}

/// Banner showing the winner.
class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.winner});

  final FinalRanking winner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bonusRank.withValues(alpha: 0.3),
            AppTheme.primary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.bonusRank.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Crown icon
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: AppTheme.bonusRank,
          ),
          const SizedBox(height: 8),
          Text(
            'Winner!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.bonusRank,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            winner.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${winner.score} points',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// List of all player rankings.
class _RankingsList extends StatelessWidget {
  const _RankingsList({
    required this.rankings,
    required this.currentPlayerId,
  });

  final List<FinalRanking> rankings;
  final String? currentPlayerId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: rankings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        final isMe = ranking.playerId == currentPlayerId;
        return _RankingTile(
          ranking: ranking,
          isMe: isMe,
        );
      },
    );
  }
}

/// Single ranking tile.
class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.ranking,
    required this.isMe,
  });

  final FinalRanking ranking;
  final bool isMe;

  Color _getRankColor() {
    return switch (ranking.rank) {
      1 => AppTheme.bonusRank, // Gold
      2 => const Color(0xFFC0C0C0), // Silver
      3 => const Color(0xFFCD7F32), // Bronze
      _ => AppTheme.textSecondary,
    };
  }

  IconData? _getRankIcon() {
    return switch (ranking.rank) {
      1 => Icons.emoji_events,
      2 => Icons.workspace_premium,
      3 => Icons.workspace_premium,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    final rankIcon = _getRankIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primary.withValues(alpha: 0.15)
            : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank indicator
          SizedBox(
            width: 40,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 24)
                : Text(
                    '#${ranking.rank}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: ranking.rank == 1
                  ? LinearGradient(
                      colors: [
                        AppTheme.bonusRank,
                        AppTheme.bonusRank.withValues(alpha: 0.7),
                      ],
                    )
                  : AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                ranking.name.isNotEmpty ? ranking.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ranking.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (ranking.correctAnswers > 0)
                  Text(
                    '${ranking.correctAnswers} correct',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          // Score
          Text(
            '${ranking.score}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ranking.rank == 1 ? AppTheme.bonusRank : null,
                ),
          ),
        ],
      ),
    );
  }
}
