import 'package:share_plus/share_plus.dart';

/// Service for sharing game content via native share sheet.
class ShareService {
  ShareService._();

  static final ShareService instance = ShareService._();

  /// Base URL for the game
  static const _baseUrl = 'https://aint-real.com';

  /// Share a game invite link.
  Future<void> shareGameInvite({
    required String gameCode,
    String? playerName,
  }) async {
    final inviteUrl = '$_baseUrl/play/#/join/$gameCode';
    final text = playerName != null
        ? "$playerName invited you to play AIn't Real!\n\nCan you spot the AI? Join the game:\n$inviteUrl"
        : "You're invited to play AIn't Real!\n\nCan you spot the AI? Join the game:\n$inviteUrl";

    await Share.share(
      text,
      subject: "Join my AIn't Real game!",
    );
  }

  /// Share game results.
  Future<void> shareResults({
    required int score,
    required int correctAnswers,
    required int totalRounds,
    required String gameMode,
    int? rank,
    int? totalPlayers,
    int? bestStreak,
  }) async {
    final buffer = StringBuffer();

    // Header based on mode
    if (gameMode == 'marathon') {
      if (correctAnswers >= totalRounds) {
        buffer.writeln("I completed the AIn't Real Marathon with a PERFECT score!");
      } else {
        buffer.writeln("I made it $correctAnswers rounds in the AIn't Real Marathon!");
      }
    } else if (gameMode == 'classic') {
      buffer.writeln("I scored $score points in AIn't Real!");
    } else {
      // Party mode
      if (rank == 1) {
        buffer.writeln("I won at AIn't Real!");
      } else {
        buffer.writeln("I played AIn't Real!");
      }
    }

    buffer.writeln();

    // Stats
    buffer.writeln('Score: $score');
    buffer.writeln('Correct: $correctAnswers/$totalRounds');

    if (bestStreak != null && bestStreak > 1) {
      buffer.writeln('Best Streak: $bestStreak');
    }

    if (rank != null && totalPlayers != null && totalPlayers > 1) {
      buffer.writeln('Rank: #$rank of $totalPlayers');
    }

    buffer.writeln();
    buffer.writeln('Can you spot the AI? Play now:');
    buffer.writeln('$_baseUrl/play/');

    await Share.share(
      buffer.toString(),
      subject: "My AIn't Real Score",
    );
  }

  /// Share app download link.
  Future<void> shareApp() async {
    const text = "Check out AIn't Real - a game where you try to spot the AI-generated image!\n\n"
        "Can you tell what's real?\n\n"
        "$_baseUrl";

    await Share.share(
      text,
      subject: "AIn't Real - Spot the AI",
    );
  }
}
