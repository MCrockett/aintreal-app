/// Guess on open: the pair on the home screen and the server's verdict.
library;

/// A home pair. The server keeps the answer; [pairToken] carries it,
/// encrypted, to the guess endpoint.
class HomePair {
  const HomePair({
    required this.leftUrl,
    required this.rightUrl,
    required this.pairToken,
    this.category,
    this.photographer,
  });

  final String leftUrl;
  final String rightUrl;
  final String pairToken;
  final String? category;
  final String? photographer;
}

/// The server-checked guess. [resultToken] makes it round 1 of a Classic game.
class GuessResult {
  const GuessResult({
    required this.correct,
    required this.aiSide,
    required this.resultToken,
  });

  final bool correct;

  /// 'left' or 'right'.
  final String aiSide;
  final String resultToken;
}

/// Why a home pair request failed.
sealed class GuessFailure implements Exception {
  const GuessFailure();
}

/// The pair token expired or was rejected; load a fresh pair quietly.
class TokenExpired extends GuessFailure {
  const TokenExpired();
}

/// Anything else: offline, server error, empty pool.
class NetworkFailure extends GuessFailure {
  const NetworkFailure();
}
