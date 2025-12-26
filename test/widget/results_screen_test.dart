import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/websocket/game_state_provider.dart';

void main() {
  Widget createTestApp({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('WinnerBanner tests', () {
    testWidgets('displays winner name', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestWinnerBanner(
          name: 'Alice',
          score: 600,
        ),
      ));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays Winner! text', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestWinnerBanner(
          name: 'Bob',
          score: 500,
        ),
      ));

      expect(find.text('Winner!'), findsOneWidget);
    });

    testWidgets('displays score with points label', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestWinnerBanner(
          name: 'Alice',
          score: 750,
        ),
      ));

      expect(find.text('750 points'), findsOneWidget);
    });

    testWidgets('displays trophy icon', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestWinnerBanner(
          name: 'Alice',
          score: 600,
        ),
      ));

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });
  });

  group('SoloResultBanner tests', () {
    testWidgets('displays score', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestSoloResultBanner(
          score: 450,
          correctAnswers: 5,
          totalRounds: 6,
          isMarathonPerfect: false,
        ),
      ));

      expect(find.text('450'), findsOneWidget);
    });

    testWidgets('displays correct answers out of total', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestSoloResultBanner(
          score: 500,
          correctAnswers: 5,
          totalRounds: 6,
          isMarathonPerfect: false,
        ),
      ));

      expect(find.text('5 / 6 correct'), findsOneWidget);
    });

    testWidgets('displays Your Score label for normal solo', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestSoloResultBanner(
          score: 400,
          correctAnswers: 4,
          totalRounds: 6,
          isMarathonPerfect: false,
        ),
      ));

      expect(find.text('Your Score'), findsOneWidget);
    });

    testWidgets('displays PERFECT! for marathon perfect', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestSoloResultBanner(
          score: 2600,
          correctAnswers: 26,
          totalRounds: 26,
          isMarathonPerfect: true,
        ),
      ));

      expect(find.text('PERFECT!'), findsOneWidget);
      expect(find.text('Marathon Complete'), findsOneWidget);
    });

    testWidgets('displays average response time', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestSoloResultBanner(
          score: 500,
          correctAnswers: 5,
          totalRounds: 6,
          isMarathonPerfect: false,
          avgResponseTime: 5500, // 5.5s including 3s countdown = 2.5s display
        ),
      ));

      expect(find.text('2.5s'), findsOneWidget);
      expect(find.text('Avg Response'), findsOneWidget);
    });

    testWidgets('displays best streak', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestSoloResultBanner(
          score: 500,
          correctAnswers: 5,
          totalRounds: 6,
          isMarathonPerfect: false,
          bestStreak: 4,
        ),
      ));

      expect(find.text('4'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
    });
  });

  group('RankingTile tests', () {
    testWidgets('displays player name', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 1,
          name: 'Alice',
          score: 600,
          correctAnswers: 5,
          isMe: false,
        ),
      ));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays player score', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 2,
          name: 'Bob',
          score: 450,
          correctAnswers: 4,
          isMe: false,
        ),
      ));

      expect(find.text('450'), findsOneWidget);
    });

    testWidgets('displays correct count', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 1,
          name: 'Alice',
          score: 600,
          correctAnswers: 5,
          isMe: false,
        ),
      ));

      expect(find.text('5 correct'), findsOneWidget);
    });

    testWidgets('shows You badge for current player', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 2,
          name: 'Bob',
          score: 450,
          correctAnswers: 4,
          isMe: true,
        ),
      ));

      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('shows trophy icon for rank 1', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 1,
          name: 'Alice',
          score: 600,
          correctAnswers: 5,
          isMe: false,
        ),
      ));

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('shows medal icon for rank 2', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 2,
          name: 'Bob',
          score: 450,
          correctAnswers: 4,
          isMe: false,
        ),
      ));

      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('shows rank number for rank > 3', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 5,
          name: 'Eve',
          score: 200,
          correctAnswers: 2,
          isMe: false,
        ),
      ));

      expect(find.text('#5'), findsOneWidget);
    });

    testWidgets('displays player initial in avatar', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestRankingTile(
          rank: 1,
          name: 'Charlie',
          score: 700,
          correctAnswers: 6,
          isMe: false,
        ),
      ));

      expect(find.text('C'), findsOneWidget);
    });
  });

  group('Header tests', () {
    testWidgets('displays Game Over! text', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                'Game Over!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Game Over!'), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('Action buttons tests', () {
    testWidgets('shows Play Again button for host', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Play Again'),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('Play Again'), findsOneWidget);
    });

    testWidgets('shows New Game button for host', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: OutlinedButton(
          onPressed: () {},
          child: const Text('New Game'),
        ),
      ));

      expect(find.text('New Game'), findsOneWidget);
    });

    testWidgets('shows waiting message for non-host', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Container(
          padding: const EdgeInsets.all(16),
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
              const Text('Waiting for host to start next game...'),
            ],
          ),
        ),
      ));

      expect(find.text('Waiting for host to start next game...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Leave Game button for non-host', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: OutlinedButton(
          onPressed: () {},
          child: const Text('Leave Game'),
        ),
      ));

      expect(find.text('Leave Game'), findsOneWidget);
    });
  });

  group('Final Standings section tests', () {
    testWidgets('displays Final Standings header', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Final Standings'),
            Text(
              '6 rounds',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ));

      expect(find.text('Final Standings'), findsOneWidget);
    });

    testWidgets('displays round count', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Text(
          '6 rounds',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ));

      expect(find.text('6 rounds'), findsOneWidget);
    });
  });

  group('Loading state tests', () {
    testWidgets('shows loading indicator when no game over data', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading results...',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading results...'), findsOneWidget);
    });
  });

  group('Photo Credits tests', () {
    testWidgets('displays Photo Credits header', (tester) async {
      await tester.pumpWidget(createTestApp(
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
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ));

      expect(find.text('Photo Credits'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('displays expand/collapse icon', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: AppTheme.textMuted,
        ),
      ));

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}

/// Test version of winner banner.
class _TestWinnerBanner extends StatelessWidget {
  const _TestWinnerBanner({
    required this.name,
    required this.score,
  });

  final String name;
  final int score;

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
      ),
      child: Column(
        children: [
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
            name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score points',
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

/// Test version of solo result banner.
class _TestSoloResultBanner extends StatelessWidget {
  const _TestSoloResultBanner({
    required this.score,
    required this.correctAnswers,
    required this.totalRounds,
    required this.isMarathonPerfect,
    this.avgResponseTime,
    this.bestStreak = 0,
  });

  final int score;
  final int correctAnswers;
  final int totalRounds;
  final bool isMarathonPerfect;
  final int? avgResponseTime;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final displayAvgTime = avgResponseTime != null
        ? ((avgResponseTime! - 3000).clamp(0, 999999) / 1000).toStringAsFixed(1)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMarathonPerfect
              ? [
                  AppTheme.bonusRank.withValues(alpha: 0.4),
                  AppTheme.primary.withValues(alpha: 0.3),
                ]
              : [
                  AppTheme.primary.withValues(alpha: 0.3),
                  AppTheme.primaryLight.withValues(alpha: 0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (isMarathonPerfect) ...[
            const Icon(
              Icons.emoji_events,
              size: 56,
              color: AppTheme.bonusRank,
            ),
            const SizedBox(height: 8),
            Text(
              'PERFECT!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.bonusRank,
                    letterSpacing: 2,
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
            '$score',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isMarathonPerfect ? AppTheme.bonusRank : AppTheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$correctAnswers / $totalRounds correct',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (displayAvgTime != null)
                Column(
                  children: [
                    Icon(Icons.timer, size: 24, color: AppTheme.textSecondary),
                    const SizedBox(height: 4),
                    Text(
                      '${displayAvgTime}s',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Avg Response',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ),
              if (bestStreak > 0)
                Column(
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 24, color: Colors.orange),
                    const SizedBox(height: 4),
                    Text(
                      '$bestStreak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                    ),
                    Text(
                      'Best Streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Test version of ranking tile.
class _TestRankingTile extends StatelessWidget {
  const _TestRankingTile({
    required this.rank,
    required this.name,
    required this.score,
    required this.correctAnswers,
    required this.isMe,
  });

  final int rank;
  final String name;
  final int score;
  final int correctAnswers;
  final bool isMe;

  Color _getRankColor() {
    return switch (rank) {
      1 => AppTheme.bonusRank,
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppTheme.textSecondary,
    };
  }

  IconData? _getRankIcon() {
    return switch (rank) {
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
          SizedBox(
            width: 40,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 24)
                : Text(
                    '#$rank',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: rank == 1
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
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (correctAnswers > 0)
                  Text(
                    '$correctAnswers correct',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rank == 1 ? AppTheme.bonusRank : null,
                ),
          ),
        ],
      ),
    );
  }
}
