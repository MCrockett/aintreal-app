import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/env.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/ads/ad_service.dart';
import '../../core/audio/sound_service.dart';
import '../../core/sharing/share_service.dart';
import '../../core/websocket/game_state_provider.dart';
import '../../core/websocket/ws_messages.dart';
import '../../models/game.dart' hide GameState, GameStatus;
import '../../widgets/cross_platform_image.dart';
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

  /// Check if current game is a solo mode (classic or marathon)
  bool _isSoloMode(WsGameConfig? config) {
    if (config == null) return false;
    return config.mode == 'classic' || config.mode == 'marathon';
  }

  /// Convert string mode to GameMode enum
  GameMode _parseGameMode(String mode) {
    return switch (mode) {
      'classic' => GameMode.classic,
      'marathon' => GameMode.marathon,
      _ => GameMode.party,
    };
  }

  void _playAgain() {
    final gameState = ref.read(gameStateProvider);
    final config = gameState.config;

    // For solo modes, navigate to Create screen with settings preserved
    if (_isSoloMode(config)) {
      // Capture the values we need BEFORE calling leave() which clears state
      final mode = _parseGameMode(config!.mode);
      final playerName = gameState.playerName;
      final rounds = config.rounds;
      final timePerRound = config.timePerRound;
      final speedBonus = config.speedBonus;
      final randomBonuses = config.randomBonuses;

      // Disconnect and clear state
      ref.read(gameStateProvider.notifier).leave();

      // Use go() to replace navigation stack (not push which keeps old screens)
      context.go(
        AppRoutes.createGame,
        extra: {
          'mode': mode,
          'playerName': playerName,
          'rounds': rounds,
          'timePerRound': timePerRound,
          'speedBonus': speedBonus,
          'randomBonuses': randomBonuses,
        },
      );
    } else {
      // For party mode, request play again through server
      ref.read(gameStateProvider.notifier).playAgain();
    }
  }

  Future<void> _newGame() async {
    // Show interstitial ad before leaving (mobile only)
    if (!kIsWeb) {
      await AdService.instance.showInterstitialAd();
    }
    ref.read(gameStateProvider.notifier).leave();
    if (mounted) context.go('/');
  }

  Future<void> _leaveGame() async {
    // Show interstitial ad before leaving (mobile only)
    if (!kIsWeb) {
      await AdService.instance.showInterstitialAd();
    }
    ref.read(gameStateProvider.notifier).leave();
    if (mounted) context.go('/');
  }

  void _shareResults() {
    final gameState = ref.read(gameStateProvider);
    final gameOverData = gameState.gameOverData;
    final playerId = gameState.playerId;
    final config = gameState.config;

    if (gameOverData == null) return;

    // Find current player's ranking
    final myRanking = gameOverData.rankings.cast<FinalRanking?>().firstWhere(
          (r) => r?.playerId == playerId,
          orElse: () => null,
        );

    if (myRanking == null) return;

    ShareService.instance.shareResults(
      score: myRanking.score,
      correctAnswers: myRanking.correctAnswers,
      totalRounds: gameOverData.totalRounds,
      gameMode: config?.mode ?? 'party',
      rank: myRanking.rank,
      totalPlayers: gameOverData.rankings.length,
      bestStreak: myRanking.bestStreak > 0 ? myRanking.bestStreak : null,
    );
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

    // Determine if player "won" - for solo modes, check if they completed all rounds
    // Marathon: winning means completing all 26 rounds (correctAnswers == totalRounds)
    // Classic: always considered a win (completed the game)
    // Party: rank 1 is winner
    final isSolo = _isSoloMode(gameState.config);
    final isMarathon = gameState.config?.mode == 'marathon';
    final bool isWinner;
    if (isMarathon) {
      // Marathon: win only if completed all rounds
      isWinner = myRanking != null && myRanking.correctAnswers >= totalRounds;
    } else if (isSolo) {
      // Classic solo: always play victory (they completed the game)
      isWinner = true;
    } else {
      // Party mode: rank 1 wins
      isWinner = myRanking?.rank == 1;
    }

    // Play victory or game over sound
    _playGameEndSound(isWinner);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveGame();
      },
      child: GradientBackground(
        child: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Share button
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: _shareResults,
                              tooltip: 'Share Results',
                            ),
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

                      // Winner announcement (party mode) or Score summary (solo mode)
                      if (rankings.isNotEmpty)
                        _isSoloMode(gameState.config)
                            ? _SoloResultBanner(
                                ranking: rankings.first,
                                totalRounds: totalRounds,
                                isMarathonPerfect: isMarathon &&
                                    rankings.first.correctAnswers >= totalRounds,
                              )
                            : _WinnerBanner(winner: rankings.first),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Rankings list (only for party mode with multiple players)
                if (!_isSoloMode(gameState.config))
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
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
                        ],
                      ),
                    ),
                  ),
                if (!_isSoloMode(gameState.config))
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ranking = rankings[index];
                          final isMe = ranking.playerId == playerId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RankingTile(
                              ranking: ranking,
                              isMe: isMe,
                            ),
                          );
                        },
                        childCount: rankings.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Photo credits (if available)
                      if (gameOverData.credits != null &&
                          gameOverData.credits!.isNotEmpty)
                        _PhotographerCredits(credits: gameOverData.credits!),

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
                                  border: Border.all(
                                    color: AppTheme.secondary,
                                    width: 2,
                                  ),
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

/// Simple result banner for solo modes (no "Winner!" text).
class _SoloResultBanner extends StatelessWidget {
  const _SoloResultBanner({
    required this.ranking,
    required this.totalRounds,
    this.isMarathonPerfect = false,
  });

  final FinalRanking ranking;
  final int totalRounds;
  final bool isMarathonPerfect;

  @override
  Widget build(BuildContext context) {
    // Calculate average response time for display (subtract 3s countdown)
    final avgResponseMs = ranking.avgResponseTime;
    final displayAvgTime = avgResponseMs != null
        ? ((avgResponseMs - 3000).clamp(0, 999999) / 1000).toStringAsFixed(1)
        : null;

    // Special golden theme for marathon perfect
    final gradientColors = isMarathonPerfect
        ? [
            AppTheme.bonusRank.withValues(alpha: 0.4),
            AppTheme.primary.withValues(alpha: 0.3),
          ]
        : [
            AppTheme.primary.withValues(alpha: 0.3),
            AppTheme.primaryLight.withValues(alpha: 0.3),
          ];

    final borderColor = isMarathonPerfect
        ? AppTheme.bonusRank.withValues(alpha: 0.7)
        : AppTheme.primary.withValues(alpha: 0.5);

    final scoreColor = isMarathonPerfect ? AppTheme.bonusRank : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isMarathonPerfect ? 3 : 2,
        ),
      ),
      child: Column(
        children: [
          // Marathon Perfect celebration header
          if (isMarathonPerfect) ...[
            const Icon(
              Icons.emoji_events,
              size: 56,
              color: AppTheme.bonusRank,
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.bonusRank, Color(0xFFFFD700)],
              ).createShader(bounds),
              child: Text(
                'PERFECT!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Marathon Complete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.bonusRank,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            isMarathonPerfect ? 'Final Score' : 'Your Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ranking.score}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ranking.correctAnswers} / $totalRounds correct',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Average response time
              if (displayAvgTime != null)
                _StatItem(
                  icon: Icons.timer,
                  value: '${displayAvgTime}s',
                  label: 'Avg Response',
                ),
              // Best streak
              if (ranking.bestStreak > 0)
                _StatItem(
                  icon: Icons.local_fire_department,
                  value: '${ranking.bestStreak}',
                  label: 'Best Streak',
                  color: Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small stat item for display in result banners.
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
        ),
      ],
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

/// Collapsible section showing photographer credits with thumbnails.
class _PhotographerCredits extends StatefulWidget {
  const _PhotographerCredits({required this.credits});

  final List<PhotographerCredit> credits;

  @override
  State<_PhotographerCredits> createState() => _PhotographerCreditsState();
}

class _PhotographerCreditsState extends State<_PhotographerCredits> {
  bool _isExpanded = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deduplicate photographers by name
    final uniqueCredits = <String, PhotographerCredit>{};
    for (final credit in widget.credits) {
      uniqueCredits[credit.photographer] = credit;
    }
    final credits = uniqueCredits.values.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Header button
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Photo Credits',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content - list of credits with thumbnails
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: credits.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppTheme.backgroundLight,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final credit = credits[index];
                  return InkWell(
                    onTap: () => _openUrl(credit.photographerUrl),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Thumbnail image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: credit.thumbnailUrl != null
                                ? SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CrossPlatformImage(
                                      imageUrl: '${Env.apiBase}${credit.thumbnailUrl!}',
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          _PlaceholderThumbnail(),
                                      errorWidget: (context, url, error) =>
                                          _PlaceholderThumbnail(),
                                    ),
                                  )
                                : _PlaceholderThumbnail(),
                          ),
                          const SizedBox(width: 12),
                          // Photographer name
                          Expanded(
                            child: Text(
                              credit.photographer,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // External link icon
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: AppTheme.primary.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Placeholder thumbnail when image is unavailable.
class _PlaceholderThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.image,
        size: 24,
        color: AppTheme.textMuted,
      ),
    );
  }
}
