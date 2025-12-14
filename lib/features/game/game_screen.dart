import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../core/websocket/game_state_provider.dart';
import '../../widgets/gradient_background.dart';

/// Game screen for active gameplay with image selection.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.gameCode,
  });

  final String gameCode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  // Timer for countdown
  Timer? _roundTimer;
  int _remainingSeconds = 0;
  DateTime? _roundStartTime;

  // Animation controller for timer bar
  AnimationController? _timerController;

  // Get Ready countdown
  bool _showGetReady = true;
  int _getReadyCount = 3;
  Timer? _getReadyTimer;

  @override
  void initState() {
    super.initState();
    _startGetReadyCountdown();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _getReadyTimer?.cancel();
    _timerController?.dispose();
    super.dispose();
  }

  void _startGetReadyCountdown() {
    _getReadyCount = 3;
    _showGetReady = true;

    _getReadyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_getReadyCount > 1) {
        setState(() => _getReadyCount--);
      } else {
        timer.cancel();
        setState(() => _showGetReady = false);
        _startRoundTimer();
      }
    });
  }

  void _startRoundTimer() {
    final gameState = ref.read(gameStateProvider);
    final config = gameState.config;
    if (config == null) return;

    _remainingSeconds = config.timePerRound;
    _roundStartTime = DateTime.now();

    // Setup animation controller for smooth timer bar
    _timerController?.dispose();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: config.timePerRound),
    );
    _timerController!.forward();

    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onImageTap(String choice) {
    final gameState = ref.read(gameStateProvider);
    if (gameState.roundData?.hasAnswered == true) return;

    // Calculate response time
    final responseTime = _roundStartTime != null
        ? DateTime.now().difference(_roundStartTime!).inMilliseconds
        : 0;

    // Submit answer
    ref.read(gameStateProvider.notifier).submitAnswer(choice, responseTime);

    // Stop timer
    _roundTimer?.cancel();
    _timerController?.stop();
  }

  String _buildImageUrl(String relativePath) {
    // Build full URL from relative path
    return '${Env.apiBase}$relativePath';
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final roundData = gameState.roundData;
    final config = gameState.config;

    // Listen for state changes
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      debugPrint('GameScreen state change: status=${next.status}, round=${next.roundData?.round}, prevRound=${previous?.roundData?.round}');

      // New round started
      if (next.roundData != null &&
          previous?.roundData?.round != next.roundData?.round) {
        debugPrint('New round detected, starting countdown');
        _startGetReadyCountdown();
      }

      // Game over - navigate to results
      if (next.status == GameStatus.finished && next.gameOverData != null) {
        debugPrint('Game finished! Navigating to results...');
        context.go('/results/${widget.gameCode}');
      }

      // Show reveal (in party mode, server sends reveal after all answered)
      if (next.status == GameStatus.revealing && next.revealData != null) {
        debugPrint('Reveal received for round ${next.revealData?.round}');
        // Could show reveal animation here
        // For now, auto-advance to next round or results
      }
    });

    // Handle no round data (shouldn't happen normally)
    if (roundData == null) {
      return GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading round...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasAnswered = roundData.hasAnswered;
    final playerChoice = roundData.playerChoice;
    final aiPosition = roundData.aiPosition;
    // Player is correct if they picked the AI image (playerChoice == aiPosition)
    final isCorrect =
        hasAnswered && playerChoice != null && playerChoice == aiPosition;

    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Header with round info
            _GameHeader(
              currentRound: roundData.round,
              totalRounds: roundData.totalRounds,
              remainingSeconds: _remainingSeconds,
              totalSeconds: config?.timePerRound ?? 5,
              timerProgress: _timerController?.value ?? 0,
              answeredCount: roundData.answeredCount,
              totalPlayers: roundData.totalPlayers,
            ),

            // Main game area
            Expanded(
              child: Stack(
                children: [
                  // Images
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Top image
                        Expanded(
                          child: _GameImage(
                            imageUrl: _buildImageUrl(roundData.topUrl),
                            position: 'top',
                            onTap: hasAnswered ? null : () => _onImageTap('top'),
                            isSelected: playerChoice == 'top',
                            isAi: aiPosition == 'top',
                            showLabel: hasAnswered,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bottom image
                        Expanded(
                          child: _GameImage(
                            imageUrl: _buildImageUrl(roundData.bottomUrl),
                            position: 'bottom',
                            onTap:
                                hasAnswered ? null : () => _onImageTap('bottom'),
                            isSelected: playerChoice == 'bottom',
                            isAi: aiPosition == 'bottom',
                            showLabel: hasAnswered,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Get Ready overlay
                  if (_showGetReady)
                    Container(
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Round ${roundData.round}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _getReadyCount.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: 120,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Get Ready!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Result overlay after answering
                  if (hasAnswered && !_showGetReady)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppTheme.correctAnswer
                                : AppTheme.wrongAnswer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isCorrect
                                        ? AppTheme.correctAnswer
                                        : AppTheme.wrongAnswer)
                                    .withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            isCorrect ? 'Correct!' : 'Wrong!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header showing round info and timer.
class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.currentRound,
    required this.totalRounds,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.timerProgress,
    required this.answeredCount,
    required this.totalPlayers,
  });

  final int currentRound;
  final int totalRounds;
  final int remainingSeconds;
  final int totalSeconds;
  final double timerProgress;
  final int answeredCount;
  final int totalPlayers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Round info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Round counter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Round $currentRound / $totalRounds',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Timer display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: remainingSeconds <= 2
                      ? AppTheme.wrongAnswer.withValues(alpha: 0.3)
                      : AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$remainingSeconds',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: remainingSeconds <= 2
                            ? AppTheme.wrongAnswer
                            : AppTheme.textPrimary,
                      ),
                ),
              ),
              // Answered count
              if (totalPlayers > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.correctAnswer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$answeredCount/$totalPlayers',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 8),
          // Timer bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1 - timerProgress,
              backgroundColor: AppTheme.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingSeconds <= 2 ? AppTheme.wrongAnswer : AppTheme.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable game image with labels.
class _GameImage extends StatelessWidget {
  const _GameImage({
    required this.imageUrl,
    required this.position,
    required this.onTap,
    required this.isSelected,
    required this.isAi,
    required this.showLabel,
  });

  final String imageUrl;
  final String position;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isAi;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: isAi ? AppTheme.wrongAnswer : AppTheme.correctAnswer,
                  width: 4,
                )
              : Border.all(color: AppTheme.secondary, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isAi ? AppTheme.wrongAnswer : AppTheme.correctAnswer)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
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
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.backgroundLight,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.backgroundLight,
                  child: const Center(
                    child: Icon(Icons.error, color: AppTheme.wrongAnswer),
                  ),
                ),
              ),

              // Label overlay after answering
              if (showLabel)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    offset: Offset.zero,
                    duration: const Duration(milliseconds: 300),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isAi
                                  ? AppTheme.wrongAnswer
                                  : AppTheme.correctAnswer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAi ? 'AI' : 'REAL',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Tap hint when not answered
              if (!showLabel && onTap != null)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tap if this is AI',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
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
