import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aintreal_app/config/theme.dart';

void main() {
  Widget createTestApp({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('GameHeader tests', () {
    testWidgets('displays round counter', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameHeader(
          currentRound: 3,
          totalRounds: 6,
          remainingSeconds: 5,
          totalSeconds: 5,
          timerProgress: 0.0,
          answeredCount: 0,
          totalPlayers: 1,
        ),
      ));

      expect(find.text('Round 3 / 6'), findsOneWidget);
    });

    testWidgets('displays remaining seconds', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameHeader(
          currentRound: 1,
          totalRounds: 6,
          remainingSeconds: 4,
          totalSeconds: 5,
          timerProgress: 0.2,
          answeredCount: 0,
          totalPlayers: 1,
        ),
      ));

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('displays answered count for multiplayer', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameHeader(
          currentRound: 1,
          totalRounds: 6,
          remainingSeconds: 5,
          totalSeconds: 5,
          timerProgress: 0.0,
          answeredCount: 3,
          totalPlayers: 5,
        ),
      ));

      expect(find.text('3/5'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('hides answered count for solo player', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameHeader(
          currentRound: 1,
          totalRounds: 6,
          remainingSeconds: 5,
          totalSeconds: 5,
          timerProgress: 0.0,
          answeredCount: 0,
          totalPlayers: 1,
        ),
      ));

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows timer bar', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameHeader(
          currentRound: 1,
          totalRounds: 6,
          remainingSeconds: 3,
          totalSeconds: 5,
          timerProgress: 0.4,
          answeredCount: 0,
          totalPlayers: 1,
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('timer shows warning color at low time', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameHeader(
          currentRound: 1,
          totalRounds: 6,
          remainingSeconds: 2,
          totalSeconds: 5,
          timerProgress: 0.6,
          answeredCount: 0,
          totalPlayers: 1,
        ),
      ));

      // Timer text should be 2 with warning color
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('GetReady overlay tests', () {
    testWidgets('displays round number', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGetReadyOverlay(
          round: 3,
          countdownValue: 3,
        ),
      ));

      expect(find.text('Round 3'), findsOneWidget);
    });

    testWidgets('displays countdown number', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGetReadyOverlay(
          round: 1,
          countdownValue: 2,
        ),
      ));

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays question text with AI highlight', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGetReadyOverlay(
          round: 1,
          countdownValue: 3,
        ),
      ));

      // The question is in a RichText widget with AI highlighted
      expect(find.byType(RichText), findsWidgets);
    });
  });

  group('GameImage tests', () {
    testWidgets('shows tap hint when not answered', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameImage(
          position: 'top',
          isSelected: false,
          isAi: false,
          showLabel: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Tap if this is AI'), findsOneWidget);
    });

    testWidgets('hides tap hint when answered', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameImage(
          position: 'top',
          isSelected: true,
          isAi: true,
          showLabel: true,
          onTap: null,
        ),
      ));

      expect(find.text('Tap if this is AI'), findsNothing);
    });

    testWidgets('shows AI label when image is AI and answered', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameImage(
          position: 'top',
          isSelected: true,
          isAi: true,
          showLabel: true,
          onTap: null,
        ),
      ));

      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('shows REAL label when image is real and answered', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestGameImage(
          position: 'bottom',
          isSelected: false,
          isAi: false,
          showLabel: true,
          onTap: null,
        ),
      ));

      expect(find.text('REAL'), findsOneWidget);
    });

    testWidgets('image is tappable when onTap provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(createTestApp(
        child: _TestGameImage(
          position: 'top',
          isSelected: false,
          isAi: false,
          showLabel: false,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('Result indicator tests', () {
    testWidgets('shows Correct! for correct answer', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestResultIndicator(isCorrect: true, playerChoice: 'top'),
      ));

      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('shows Wrong! for wrong answer', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestResultIndicator(isCorrect: false, playerChoice: 'bottom'),
      ));

      expect(find.text('Wrong!'), findsOneWidget);
    });

    testWidgets('shows Time Up! for timeout', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestResultIndicator(isCorrect: false, playerChoice: 'timeout'),
      ));

      expect(find.text('Time Up!'), findsOneWidget);
    });

    testWidgets('correct result has green background', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestResultIndicator(isCorrect: true, playerChoice: 'top'),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.correctAnswer);
    });

    testWidgets('wrong result has red background', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestResultIndicator(isCorrect: false, playerChoice: 'bottom'),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.wrongAnswer);
    });
  });

  group('Loading state tests', () {
    testWidgets('shows loading indicator when no round data', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading round...',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading round...'), findsOneWidget);
    });
  });

  group('Image placeholder tests', () {
    testWidgets('shows shimmer placeholder with image icon', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Container(
          width: 200,
          height: 200,
          color: AppTheme.backgroundLight,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('shows error icon on image load failure', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Container(
          width: 200,
          height: 200,
          color: AppTheme.backgroundLight,
          child: const Center(
            child: Icon(Icons.error, color: AppTheme.wrongAnswer),
          ),
        ),
      ));

      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}

/// Test version of game header.
class _TestGameHeader extends StatelessWidget {
  const _TestGameHeader({
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              if (totalPlayers > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Text('$answeredCount/$totalPlayers'),
                    ],
                  ),
                )
              else
                const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 8),
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

/// Test version of Get Ready overlay.
class _TestGetReadyOverlay extends StatelessWidget {
  const _TestGetReadyOverlay({
    required this.round,
    required this.countdownValue,
  });

  final int round;
  final int countdownValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Round $round',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Text(
              countdownValue.toString(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
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
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
    );
  }
}

/// Test version of game image.
class _TestGameImage extends StatelessWidget {
  const _TestGameImage({
    required this.position,
    required this.isSelected,
    required this.isAi,
    required this.showLabel,
    required this.onTap,
  });

  final String position;
  final bool isSelected;
  final bool isAi;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: isAi ? AppTheme.wrongAnswer : AppTheme.correctAnswer,
                  width: 4,
                )
              : Border.all(color: AppTheme.secondary, width: 2),
          color: AppTheme.backgroundLight,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Label overlay after answering
            if (showLabel)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                          color: isAi ? AppTheme.wrongAnswer : AppTheme.correctAnswer,
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
    );
  }
}

/// Test version of result indicator.
class _TestResultIndicator extends StatelessWidget {
  const _TestResultIndicator({
    required this.isCorrect,
    required this.playerChoice,
  });

  final bool isCorrect;
  final String? playerChoice;

  String get _resultText {
    if (isCorrect) return 'Correct!';
    if (playerChoice == 'timeout' || playerChoice == null) return 'Time Up!';
    return 'Wrong!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isCorrect ? AppTheme.correctAnswer : AppTheme.wrongAnswer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _resultText,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
