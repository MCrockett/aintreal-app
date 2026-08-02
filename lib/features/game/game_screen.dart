import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../core/audio/sound_service.dart';
import '../../core/websocket/game_state_provider.dart';
import '../../core/websocket/ws_client.dart';
import '../../widgets/connection_overlay.dart';
import '../../widgets/cross_platform_image.dart';
import '../../widgets/gradient_background.dart';

/// Service for preloading game images.
class ImagePreloader {
  static final ImagePreloader instance = ImagePreloader._();
  ImagePreloader._();

  final Set<String> _preloadedUrls = {};

  /// Preload images into the cache during Get Ready countdown.
  Future<void> preloadImages(BuildContext context, List<String> urls) async {
    for (final url in urls) {
      if (_preloadedUrls.contains(url)) continue;

      try {
        // Use cross-platform provider to cache the image
        await CrossPlatformImageProvider.preload(context, url);
        _preloadedUrls.add(url);
        debugPrint('Preloaded image: $url');
      } catch (e) {
        debugPrint('Failed to preload image: $url - $e');
      }
    }
  }

  /// Clear preloaded URLs tracking (call when game ends).
  void clear() {
    _preloadedUrls.clear();
  }
}

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

  // Connection loss tracking
  bool _timerPausedForReconnect = false;

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
    // A round restored from a mid-round resync arrives already in progress —
    // fast-forward instead of replaying Get Ready + a full timer.
    final elapsedMs = ref.read(gameStateProvider).roundData?.elapsedMs ?? 0;
    if (elapsedMs >= _getReadyMs) {
      _resumeRoundFromElapsed(elapsedMs);
      return;
    }

    _getReadyCount = 3 - elapsedMs ~/ 1000;
    _showGetReady = true;

    // Start tracking response time from round start (before Get Ready ends)
    // This allows server to detect early clicks (responseTime < 3000ms)
    _roundStartTime = DateTime.now().subtract(Duration(milliseconds: elapsedMs));

    // Play tick sound for initial count
    SoundService.instance.playTick();

    // Preload current round images during the countdown
    _preloadCurrentRoundImages();

    _getReadyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_getReadyCount > 1) {
        setState(() => _getReadyCount--);
        // Play tick sound for each countdown
        SoundService.instance.playTick();
      } else {
        timer.cancel();
        setState(() => _showGetReady = false);
        // Play round start sound
        SoundService.instance.playRoundStart();
        _startRoundTimer();
      }
    });
  }

  /// Preload current round images during Get Ready countdown.
  void _preloadCurrentRoundImages() {
    final roundData = ref.read(gameStateProvider).roundData;
    if (roundData == null) return;

    final urls = [
      _buildImageUrl(roundData.topUrl),
      _buildImageUrl(roundData.bottomUrl),
    ];

    // Preload in background (don't await - let it run during countdown)
    ImagePreloader.instance.preloadImages(context, urls);
  }

  void _startRoundTimer() {
    final gameState = ref.read(gameStateProvider);
    final config = gameState.config;
    if (config == null) return;

    _remainingSeconds = config.timePerRound;
    // Note: _roundStartTime is already set in _startGetReadyCountdown
    // This allows early click detection (clicks during Get Ready countdown)

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
        // Play tick sound for last 3 seconds
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          SoundService.instance.playTick();
        }
        // Play time up warning at 0
        if (_remainingSeconds == 0) {
          SoundService.instance.playTimeUp();
          // Auto-submit timeout when timer expires (for solo games this is critical)
          _onTimeExpired();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Get Ready countdown duration — must match the server's
  /// clientGetReadyDelay so resync elapsed math lines up.
  static const int _getReadyMs = 3000;

  /// Resume a round that was already in progress when we (re)joined it —
  /// mid-round resync via the connected message's roundState.
  void _resumeRoundFromElapsed(int elapsedMs) {
    final gameState = ref.read(gameStateProvider);
    // The resync snapshot's round-scoped time is authoritative; config is
    // the fallback for safety only.
    final totalSeconds = gameState.roundData?.timeSeconds ??
        gameState.config?.timePerRound ??
        5;
    final playElapsedMs = elapsedMs - _getReadyMs;
    final remaining = totalSeconds - (playElapsedMs / 1000).floor();

    // Direct field assignment (no setState) — callers run from initState or a
    // provider listener whose state change already triggers a rebuild.
    _showGetReady = false;
    _roundStartTime =
        DateTime.now().subtract(Duration(milliseconds: elapsedMs));
    _remainingSeconds = remaining.clamp(0, totalSeconds);

    _preloadCurrentRoundImages();

    if (gameState.roundData?.hasAnswered == true) return;

    if (_remainingSeconds <= 0) {
      // Round effectively over for us. The server rejects late answers and
      // sends a timed-out answer_result at round end; submitting here just
      // settles the local UI into the answered state immediately.
      // Post-frame: this can run from initState, where provider writes throw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onTimeExpired();
      });
      return;
    }

    // Fast-forward the timer bar and resume the countdown
    _timerController?.dispose();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalSeconds),
    );
    _timerController!.value =
        ((totalSeconds - _remainingSeconds) / totalSeconds).clamp(0.0, 1.0);
    _timerController!.forward();

    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          SoundService.instance.playTick();
        }
        if (_remainingSeconds == 0) {
          SoundService.instance.playTimeUp();
          _onTimeExpired();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Called when the timer expires without an answer
  void _onTimeExpired() {
    final gameState = ref.read(gameStateProvider);
    if (gameState.roundData?.hasAnswered == true) return;

    debugPrint('Timer expired! Auto-submitting timeout answer');

    // Submit a "timeout" answer - pick a random wrong answer
    // For timeout, we submit with the full time as response time
    final config = gameState.config;
    final responseTime = (config?.timePerRound ?? 5) * 1000;

    // Submit answer indicating timeout (pick 'none' or empty string)
    // The server should treat this as incorrect
    ref.read(gameStateProvider.notifier).submitAnswer('timeout', responseTime);

    // Stop timer
    _roundTimer?.cancel();
    _timerController?.stop();
  }

  void _pauseTimerForReconnect() {
    if (_timerPausedForReconnect) return;
    _timerPausedForReconnect = true;
    _roundTimer?.cancel();
    _timerController?.stop();
    _getReadyTimer?.cancel();
  }

  void _resumeTimerAfterReconnect() {
    if (!_timerPausedForReconnect) return;
    _timerPausedForReconnect = false;

    // Resume Get Ready countdown if it was active
    if (_showGetReady) {
      _getReadyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_getReadyCount > 1) {
          setState(() => _getReadyCount--);
          SoundService.instance.playTick();
        } else {
          timer.cancel();
          setState(() => _showGetReady = false);
          SoundService.instance.playRoundStart();
          _startRoundTimer();
        }
      });
      return;
    }

    // Resume round timer if there's time remaining
    if (_remainingSeconds > 0) {
      final config = ref.read(gameStateProvider).config;
      final totalSeconds = config?.timePerRound ?? 5;
      final elapsed = totalSeconds - _remainingSeconds;
      _timerController?.value = elapsed / totalSeconds;
      _timerController?.forward();

      _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            SoundService.instance.playTick();
          }
          if (_remainingSeconds == 0) {
            SoundService.instance.playTimeUp();
            _onTimeExpired();
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _returnHome() {
    ref.read(gameStateProvider.notifier).disconnect();
    context.go('/');
  }

  void _confirmLeaveGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text('You will lose your progress in this game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _returnHome();
            },
            child: Text(
              'Leave',
              style: TextStyle(color: AppTheme.wrongAnswer),
            ),
          ),
        ],
      ),
    );
  }

  void _onImageTap(String choice) {
    // Block clicks during Get Ready countdown
    if (_showGetReady) return;

    final gameState = ref.read(gameStateProvider);
    if (gameState.roundData?.hasAnswered == true) return;

    // Play selection haptic
    SoundService.instance.haptic(HapticType.selection);

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

  /// Get the result text based on correctness and whether it was a timeout.
  String _getResultText(bool isCorrect, String? playerChoice) {
    if (isCorrect) {
      return 'Correct!';
    }
    // Check if it was a timeout (playerChoice is 'timeout' or null)
    if (playerChoice == 'timeout' || playerChoice == null) {
      return 'Time Up!';
    }
    return 'Wrong!';
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final roundData = gameState.roundData;
    final config = gameState.config;

    // Listen for state changes
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      debugPrint('GameScreen state change: status=${next.status}, round=${next.roundData?.round}, prevRound=${previous?.roundData?.round}');

      // Handle connection state changes - pause/resume timer
      if (next.connectionState == WsConnectionState.reconnecting &&
          previous?.connectionState != WsConnectionState.reconnecting) {
        _pauseTimerForReconnect();
      }
      if (next.connectionState == WsConnectionState.connected &&
          previous?.connectionState == WsConnectionState.reconnecting) {
        _resumeTimerAfterReconnect();
      }

      // Host left detection (guests only)
      final hostLeft = next.error == 'Host left the game' && !next.isHost;
      final hostDisconnected = !next.isHost &&
          next.connectionState == WsConnectionState.disconnected &&
          previous?.connectionState != null &&
          previous?.connectionState != WsConnectionState.disconnected;

      if (hostLeft || hostDisconnected) {
        if (next.error != null) {
          ref.read(gameStateProvider.notifier).clearError();
        }
        _roundTimer?.cancel();
        _getReadyTimer?.cancel();
        _timerController?.stop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Game Ended'),
            content: const Text('The host has left the game.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _returnHome();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // New round started
      if (next.roundData != null &&
          previous?.roundData?.round != next.roundData?.round) {
        debugPrint('New round detected, starting countdown');
        _startGetReadyCountdown();
      }

      // Game over - navigate to results
      if (next.status == GameStatus.finished && next.gameOverData != null) {
        debugPrint('Game finished! Navigating to results...');
        // For marathon mode, add a delay so player can see the wrong answer
        final isMarathon = next.config?.mode == 'marathon';
        if (isMarathon) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) context.go('/results/${widget.gameCode}');
          });
        } else {
          context.go('/results/${widget.gameCode}');
        }
      }

      // Navigate to reveal screen when revealing starts
      if (next.status == GameStatus.revealing && next.revealData != null) {
        debugPrint('Reveal received for round ${next.revealData?.round}, navigating to reveal screen');
        context.go('/reveal/${widget.gameCode}');
      }
    });

    // Handle no round data (shouldn't happen normally)
    if (roundData == null) {
      return GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _confirmLeaveGame,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading round...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasAnswered = roundData.hasAnswered;
    final playerChoice = roundData.playerChoice;
    // Where the AI is — from answer_result (new server) or round_start (old
    // server). Null until the verdict arrives, so nothing pre-answer can leak.
    final aiPosition = roundData.revealedAiPosition;
    // Null while the verdict is unknown (answered, answer_result in flight).
    final verdict = roundData.isCorrect;
    final isCorrect = verdict ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeaveGame();
      },
      child: GradientBackground(
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
              onLeave: _confirmLeaveGame,
            ),

            // Main game area
            Expanded(
              child: Stack(
                children: [
                  // Images with result indicator between them
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
                            showLabel: hasAnswered && aiPosition != null,
                            isCorrect: verdict,
                          ),
                        ),
                        // Result indicator between images (always reserve space)
                        SizedBox(
                          height: 56,
                          child: Center(
                            child: hasAnswered && !_showGetReady
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: verdict == null
                                          ? AppTheme.secondary
                                          : verdict
                                              ? AppTheme.correctAnswer
                                              : AppTheme.wrongAnswer,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (verdict == null
                                                  ? AppTheme.secondary
                                                  : verdict
                                                      ? AppTheme.correctAnswer
                                                      : AppTheme.wrongAnswer)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      verdict == null
                                          ? 'Locked in!'
                                          : _getResultText(
                                              isCorrect, playerChoice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Bottom image
                        Expanded(
                          child: _GameImage(
                            imageUrl: _buildImageUrl(roundData.bottomUrl),
                            position: 'bottom',
                            onTap:
                                hasAnswered ? null : () => _onImageTap('bottom'),
                            isSelected: playerChoice == 'bottom',
                            isAi: aiPosition == 'bottom',
                            showLabel: hasAnswered && aiPosition != null,
                            isCorrect: verdict,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Get Ready overlay - blocks taps until countdown finishes
                  if (_showGetReady)
                    Container(
                        color: Colors.black.withValues(alpha: 0.85),
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
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Which image ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: 'AI',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                    ),
                                    TextSpan(
                                      text: "n't real?",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  // Marathon Game Over overlay
                  if (gameState.status == GameStatus.finished &&
                      config?.mode == 'marathon')
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GAME OVER',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.wrongAnswer,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Final Streak: ${gameState.gameOverData?.rankings.firstOrNull?.correctAnswers ?? 0}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Connection loss overlay (topmost layer)
                  ConnectionLostOverlay(
                    connectionState: gameState.connectionState,
                    onReturnHome: _returnHome,
                  ),

                ],
              ),
            ),
          ],
        ),
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
    this.onLeave,
  });

  final int currentRound;
  final int totalRounds;
  final int remainingSeconds;
  final int totalSeconds;
  final double timerProgress;
  final int answeredCount;
  final int totalPlayers;
  final VoidCallback? onLeave;

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
              // Leave button
              if (onLeave != null)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    onPressed: onLeave,
                    color: AppTheme.textMuted,
                  ),
                ),
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
    required this.isCorrect,
  });

  final String imageUrl;
  final String position;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isAi;
  final bool showLabel;

  /// Null while the verdict is unknown — selection renders neutral until
  /// answer_result arrives.
  final bool? isCorrect;

  Color get _selectionColor => isCorrect == null
      ? AppTheme.secondary
      : isCorrect!
          ? AppTheme.correctAnswer
          : AppTheme.wrongAnswer;

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
                  color: _selectionColor,
                  width: 4,
                )
              : Border.all(color: AppTheme.secondary, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _selectionColor.withValues(alpha: 0.3),
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
              CrossPlatformImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _ShimmerPlaceholder(),
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
                              color: AppTheme.imageLabel,
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

/// Shimmer loading placeholder for images.
class _ShimmerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: Stack(
        children: [
          // Shimmer gradient animation
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundLight,
                    AppTheme.secondary.withValues(alpha: 0.3),
                    AppTheme.backgroundLight,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
          ),
          // Loading icon
          Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
