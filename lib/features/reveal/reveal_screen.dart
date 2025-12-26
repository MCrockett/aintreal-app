import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../core/audio/sound_service.dart';
import '../../core/websocket/game_state_provider.dart';
import '../../core/websocket/ws_messages.dart';
import '../../widgets/cross_platform_image.dart';
import '../../widgets/gradient_background.dart';

/// AI puns for wrong answers - each contains "AI" to be styled
const _wrongAnswerPuns = [
  'You fAIled this one!',
  "Don't despAIr!",
  'TrAIn your eyes!',
  "Don't lose fAIth!",
  'RemAIn calm, try agAIn!',
];

/// Reveal screen showing round-by-round results with the AI image revealed.
class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({
    super.key,
    required this.gameCode,
  });

  final String gameCode;

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // Track sounds to avoid duplicate plays
  bool _revealSoundPlayed = false;
  bool _resultSoundPlayed = false;
  bool _bonusSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeIn,
      ),
    );

    // Start the reveal animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _revealController.forward();
        _playRevealSound();
      }
    });
  }

  void _playRevealSound() {
    if (!_revealSoundPlayed) {
      _revealSoundPlayed = true;
      SoundService.instance.playReveal();
    }
  }

  void _playResultSound(bool isCorrect) {
    if (!_resultSoundPlayed) {
      _resultSoundPlayed = true;
      // Delay to sync with animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (isCorrect) {
          SoundService.instance.playCorrect();
        } else {
          SoundService.instance.playWrong();
        }
      });
    }
  }

  void _playBonusSound(String bonusType) {
    if (!_bonusSoundPlayed) {
      _bonusSoundPlayed = true;
      // Delay to sync with bonus card animation
      Future.delayed(const Duration(milliseconds: 700), () {
        if (bonusType == 'streak') {
          SoundService.instance.playStreak();
        } else {
          SoundService.instance.playBonus();
        }
      });
    }
  }

  void _resetSounds() {
    _revealSoundPlayed = false;
    _resultSoundPlayed = false;
    _bonusSoundPlayed = false;
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  String _buildImageUrl(String relativePath) {
    return '${Env.apiBase}$relativePath';
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final revealData = gameState.revealData;
    final playerId = gameState.playerId;

    // Listen for state changes
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      debugPrint(
          'RevealScreen state change: status=${next.status}, revealRound=${next.revealData?.round}');

      // Navigate to results when game is over
      if (next.status == GameStatus.finished && next.gameOverData != null) {
        debugPrint('Game finished! Navigating to results...');
        context.go('/results/${widget.gameCode}');
      }

      // Navigate back to game screen when a new round starts
      if (next.status == GameStatus.playing && next.roundData != null &&
          previous?.status == GameStatus.revealing) {
        debugPrint('New round starting, navigating back to game screen');
        context.go('/game/${widget.gameCode}');
      }

      // New reveal round - restart animation and sounds
      if (next.revealData != null &&
          previous?.revealData?.round != next.revealData?.round) {
        debugPrint('New reveal round: ${next.revealData?.round}');
        _resetSounds();
        _revealController.reset();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _revealController.forward();
            _playRevealSound();
          }
        });
      }
    });

    // Handle no reveal data
    if (revealData == null) {
      return GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading reveal...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final aiPosition = revealData.aiPosition;
    final results = revealData.results;
    final scores = revealData.scores;
    final bonus = revealData.bonus;

    // Find current player's result
    final myResult = results.cast<PlayerResult?>().firstWhere(
          (r) => r?.playerId == playerId,
          orElse: () => null,
        );

    // Play result sound for current player
    if (myResult != null) {
      _playResultSound(myResult.correct);
    }

    // Play bonus sound if there's a bonus
    if (bonus != null) {
      _playBonusSound(bonus.type);
    }

    // Get image URLs directly from reveal data
    final topUrl = revealData.topUrl;
    final bottomUrl = revealData.bottomUrl;

    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Round ${revealData.round} Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Images with AI reveal
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Top image
                    Expanded(
                      child: _RevealImage(
                        imageUrl: _buildImageUrl(topUrl),
                        isAi: aiPosition == 'top',
                        scaleAnimation: _scaleAnimation,
                        glowAnimation: _glowAnimation,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bottom image
                    Expanded(
                      child: _RevealImage(
                        imageUrl: _buildImageUrl(bottomUrl),
                        isAi: aiPosition == 'bottom',
                        scaleAnimation: _scaleAnimation,
                        glowAnimation: _glowAnimation,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Your result
            if (myResult != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _YourResultCard(result: myResult)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 500.ms),
              ),

            const SizedBox(height: 12),

            // Bonus (if any)
            if (bonus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BonusCard(bonus: bonus)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 700.ms)
                    .slideX(begin: -0.3, end: 0, duration: 400.ms, delay: 700.ms)
                    .shimmer(duration: 1200.ms, delay: 1100.ms),
              ),

            const SizedBox(height: 12),

            // Scores leaderboard
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scores',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _ScoresList(
                        scores: scores,
                        currentPlayerId: playerId,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Image with AI reveal animation.
class _RevealImage extends StatelessWidget {
  const _RevealImage({
    required this.imageUrl,
    required this.isAi,
    required this.scaleAnimation,
    required this.glowAnimation,
  });

  final String imageUrl;
  final bool isAi;
  final Animation<double> scaleAnimation;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: isAi ? scaleAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAi
                    ? AppTheme.wrongAnswer.withValues(alpha: glowAnimation.value)
                    : AppTheme.correctAnswer
                        .withValues(alpha: glowAnimation.value),
                width: isAi ? 4 : 2,
              ),
              boxShadow: isAi
                  ? [
                      BoxShadow(
                        color: AppTheme.wrongAnswer
                            .withValues(alpha: 0.5 * glowAnimation.value),
                        blurRadius: 20 * glowAnimation.value,
                        spreadRadius: 4 * glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  CrossPlatformImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.backgroundLight,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.backgroundLight,
                      child:
                          const Center(child: Icon(Icons.error, size: 48)),
                    ),
                  ),

                  // AI/Real label
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: glowAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isAi
                                    ? AppTheme.wrongAnswer
                                    : AppTheme.correctAnswer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAi ? Icons.smart_toy : Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAi ? 'AI Generated' : 'Real Photo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card showing the current player's result for this round.
class _YourResultCard extends StatelessWidget {
  const _YourResultCard({required this.result});

  final PlayerResult result;

  /// Build rich text with "AI" styled in primary color
  Widget _buildStyledText(BuildContext context, String text, Color baseColor) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'AI', caseSensitive: true);
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      // Add the styled "AI"
      spans.add(TextSpan(
        text: 'AI',
        style: TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ));
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: baseColor,
            ),
        children: spans,
      ),
    );
  }

  /// Build bonus chips for display (including base +100 for correct answers)
  List<Widget> _buildBonusChips(BuildContext context) {
    final chips = <Widget>[];

    void addChip(int? value, String label, Color color, IconData icon) {
      if (value != null && value > 0) {
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '+$value $label',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Add base +100 for correct answers first
    if (result.correct) {
      addChip(100, 'Correct', AppTheme.correctAnswer, Icons.check_circle);
    }

    // Add rank bonus with ordinal label
    if (result.rankBonus != null && result.rank != null) {
      final rankLabels = ['1st', '2nd', '3rd'];
      final rankLabel = result.rank! <= 3 ? rankLabels[result.rank! - 1] : '';
      addChip(result.rankBonus, rankLabel, AppTheme.bonusRank, Icons.emoji_events);
    }

    addChip(result.speedBonus, 'Speed', Colors.blue, Icons.bolt);
    addChip(result.streakBonus, 'Streak', Colors.orange, Icons.local_fire_department);
    addChip(result.luckyBonus, 'Lucky', Colors.purple, Icons.casino);
    addChip(result.comebackBonus, 'Comeback', Colors.teal, Icons.trending_up);
    addChip(result.underdogBonus, 'Underdog', Colors.indigo, Icons.pets);
    addChip(result.trickyBonus, 'Tricky', Colors.pink, Icons.psychology);
    addChip(result.slowSteadyBonus, 'Slow & Steady', Colors.brown, Icons.timer);

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = result.correct;
    final points = result.points;

    // Pick a random pun for wrong answers
    final wrongText = _wrongAnswerPuns[Random().nextInt(_wrongAnswerPuns.length)];

    final bonusChips = _buildBonusChips(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.correctAnswer.withValues(alpha: 0.2)
            : AppTheme.wrongAnswer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppTheme.correctAnswer.withValues(alpha: 0.5)
              : AppTheme.wrongAnswer.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Result icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCorrect ? AppTheme.correctAnswer : AppTheme.wrongAnswer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCorrect)
                      Text(
                        'You got it right!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.correctAnswer,
                            ),
                      )
                    else
                      _buildStyledText(context, wrongText, AppTheme.wrongAnswer),
                    if (result.responseTime > 0) Builder(
                      builder: (context) {
                        // Response time from server includes 3s countdown, subtract it for display
                        final displayTimeMs = (result.responseTime - 3000).clamp(0, 999999);
                        return Text(
                          '${(displayTimeMs / 1000).toStringAsFixed(1)}s response time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Points
              if (points > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.correctAnswer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+$points',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true, count: 2))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.15, 1.15),
                      duration: 300.ms,
                      delay: 800.ms,
                    ),
            ],
          ),
          // Bonus chips row
          if (bonusChips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: bonusChips
                  .asMap()
                  .entries
                  .map((entry) => entry.value
                      .animate()
                      .fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: 900 + entry.key * 100),
                      )
                      .slideX(
                        begin: -0.2,
                        end: 0,
                        duration: 300.ms,
                        delay: Duration(milliseconds: 900 + entry.key * 100),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card showing bonus awarded this round.
class _BonusCard extends StatelessWidget {
  const _BonusCard({required this.bonus});

  final RoundBonus bonus;

  String _getBonusLabel() {
    return switch (bonus.type) {
      'speed' => 'Speed Bonus',
      'lucky' => 'Lucky Guess',
      'fools_gold' => "Fool's Gold",
      'eagle_eye' => 'Eagle Eye',
      'comeback' => 'Comeback Kid',
      'streak' => 'On Fire!',
      _ => 'Bonus',
    };
  }

  IconData _getBonusIcon() {
    return switch (bonus.type) {
      'speed' => Icons.bolt,
      'lucky' => Icons.casino,
      'fools_gold' => Icons.warning_amber,
      'eagle_eye' => Icons.visibility,
      'comeback' => Icons.trending_up,
      'streak' => Icons.local_fire_department,
      _ => Icons.star,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.bonusRank.withValues(alpha: 0.3),
            AppTheme.primary.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.bonusRank.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getBonusIcon(),
            color: AppTheme.bonusRank,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBonusLabel(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.bonusRank,
                      ),
                ),
                Text(
                  bonus.playerName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bonusRank,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+${bonus.points}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact scores list for reveal screen.
class _ScoresList extends StatelessWidget {
  const _ScoresList({
    required this.scores,
    required this.currentPlayerId,
  });

  final List<PlayerScore> scores;
  final String? currentPlayerId;

  @override
  Widget build(BuildContext context) {
    // Sort scores descending
    final sortedScores = List<PlayerScore>.from(scores)
      ..sort((a, b) => b.score.compareTo(a.score));

    return ListView.separated(
      itemCount: sortedScores.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final score = sortedScores[index];
        final isMe = score.playerId == currentPlayerId;
        final rank = index + 1;

        return _ScoreItem(
          score: score,
          rank: rank,
          isMe: isMe,
          index: index,
        );
      },
    );
  }
}

/// Animated score item in the leaderboard.
class _ScoreItem extends StatelessWidget {
  const _ScoreItem({
    required this.score,
    required this.rank,
    required this.isMe,
    required this.index,
  });

  final PlayerScore score;
  final int rank;
  final bool isMe;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primary.withValues(alpha: 0.15)
            : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: isMe
            ? Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rank == 1
                        ? AppTheme.bonusRank
                        : AppTheme.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Row(
              children: [
                Text(
                  score.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isMe ? FontWeight.bold : null,
                      ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'You',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Score with animation
          _AnimatedScore(score: score.score, rank: rank),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 800 + (index * 100)),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: 800 + (index * 100)),
          curve: Curves.easeOutCubic,
        );
  }
}

/// Animated score counter that counts up.
class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({
    required this.score,
    required this.rank,
  });

  final int score;
  final int rank;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _scoreAnimation;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimation();

    // Start counting after a delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _controller.forward();
    });
  }

  void _setupAnimation() {
    _scoreAnimation = IntTween(begin: _previousScore, end: widget.score).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(_AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When score changes, restart animation from previous score to new score
    if (oldWidget.score != widget.score) {
      _previousScore = oldWidget.score;
      _controller.reset();
      _setupAnimation();
      // Start animation after brief delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Text(
          '${_scoreAnimation.value}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.rank == 1 ? AppTheme.bonusRank : null,
              ),
        );
      },
    );
  }
}
