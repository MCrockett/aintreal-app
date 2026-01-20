import 'package:flutter_test/flutter_test.dart';

/// Tests for ad frequency logic.
///
/// The ad frequency rules are:
/// - No ads for first 5 games
/// - Show ad on 5th game completion
/// - Then show every 3rd game (games 5, 8, 11, 14, ...)
/// - Maximum 1 ad per 5 minutes
/// - Skip if ad removal purchased

/// Pure function to test ad frequency logic (mirrors AdService.shouldShowInterstitial)
bool shouldShowAd({
  required int gamesPlayed,
  required bool adRemovalPurchased,
  required bool adReady,
  required DateTime? lastAdShown,
  required DateTime now,
  int firstAdAfterGames = 5,
  int adEveryNGames = 3,
  int minSecondsBetweenAds = 300,
}) {
  // Never show if ads removed
  if (adRemovalPurchased) return false;

  // Never show if ad not ready
  if (!adReady) return false;

  // Don't show for first N games
  if (gamesPlayed < firstAdAfterGames) return false;

  // Check frequency cap
  if (lastAdShown != null) {
    final secondsSinceLastAd = now.difference(lastAdShown).inSeconds;
    if (secondsSinceLastAd < minSecondsBetweenAds) return false;
  }

  // After first threshold, show every Nth game
  final gamesSinceFirstAd = gamesPlayed - firstAdAfterGames;
  return gamesSinceFirstAd % adEveryNGames == 0;
}

void main() {
  group('Ad Frequency Logic', () {
    final now = DateTime(2024, 1, 1, 12, 0, 0);

    group('Ad removal purchased', () {
      test('never shows ads when ad removal purchased', () {
        expect(
          shouldShowAd(
            gamesPlayed: 10,
            adRemovalPurchased: true,
            adReady: true,
            lastAdShown: null,
            now: now,
          ),
          isFalse,
        );
      });
    });

    group('Ad not ready', () {
      test('does not show when ad not loaded', () {
        expect(
          shouldShowAd(
            gamesPlayed: 10,
            adRemovalPurchased: false,
            adReady: false,
            lastAdShown: null,
            now: now,
          ),
          isFalse,
        );
      });
    });

    group('First N games grace period', () {
      test('does not show for games 0-4', () {
        for (var i = 0; i < 5; i++) {
          expect(
            shouldShowAd(
              gamesPlayed: i,
              adRemovalPurchased: false,
              adReady: true,
              lastAdShown: null,
              now: now,
            ),
            isFalse,
            reason: 'Should not show ad at game $i',
          );
        }
      });

      test('shows on game 5 (first ad)', () {
        expect(
          shouldShowAd(
            gamesPlayed: 5,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: null,
            now: now,
          ),
          isTrue,
        );
      });
    });

    group('Every Nth game after first ad', () {
      test('does not show on games 6, 7', () {
        expect(
          shouldShowAd(
            gamesPlayed: 6,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: null,
            now: now,
          ),
          isFalse,
        );
        expect(
          shouldShowAd(
            gamesPlayed: 7,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: null,
            now: now,
          ),
          isFalse,
        );
      });

      test('shows on game 8 (3 games after 5)', () {
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: null,
            now: now,
          ),
          isTrue,
        );
      });

      test('shows on games 5, 8, 11, 14, 17, 20', () {
        final expectedAdGames = [5, 8, 11, 14, 17, 20];
        for (var game in expectedAdGames) {
          expect(
            shouldShowAd(
              gamesPlayed: game,
              adRemovalPurchased: false,
              adReady: true,
              lastAdShown: null,
              now: now,
            ),
            isTrue,
            reason: 'Should show ad at game $game',
          );
        }
      });

      test('does not show on intermediate games', () {
        final noAdGames = [6, 7, 9, 10, 12, 13, 15, 16, 18, 19];
        for (var game in noAdGames) {
          expect(
            shouldShowAd(
              gamesPlayed: game,
              adRemovalPurchased: false,
              adReady: true,
              lastAdShown: null,
              now: now,
            ),
            isFalse,
            reason: 'Should not show ad at game $game',
          );
        }
      });
    });

    group('5-minute frequency cap', () {
      test('does not show if less than 5 minutes since last ad', () {
        final lastAd = now.subtract(const Duration(minutes: 4));
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: lastAd,
            now: now,
          ),
          isFalse,
        );
      });

      test('shows if exactly 5 minutes since last ad', () {
        final lastAd = now.subtract(const Duration(minutes: 5));
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: lastAd,
            now: now,
          ),
          isTrue,
        );
      });

      test('shows if more than 5 minutes since last ad', () {
        final lastAd = now.subtract(const Duration(minutes: 10));
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: lastAd,
            now: now,
          ),
          isTrue,
        );
      });

      test('does not show at 299 seconds', () {
        final lastAd = now.subtract(const Duration(seconds: 299));
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: lastAd,
            now: now,
          ),
          isFalse,
        );
      });

      test('shows at 300 seconds', () {
        final lastAd = now.subtract(const Duration(seconds: 300));
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: lastAd,
            now: now,
          ),
          isTrue,
        );
      });
    });

    group('Combined conditions', () {
      test('frequency cap takes precedence over game count', () {
        // Game 8 would normally show, but blocked by frequency cap
        final lastAd = now.subtract(const Duration(minutes: 2));
        expect(
          shouldShowAd(
            gamesPlayed: 8,
            adRemovalPurchased: false,
            adReady: true,
            lastAdShown: lastAd,
            now: now,
          ),
          isFalse,
        );
      });

      test('ad removal takes precedence over everything', () {
        expect(
          shouldShowAd(
            gamesPlayed: 100,
            adRemovalPurchased: true,
            adReady: true,
            lastAdShown: null,
            now: now,
          ),
          isFalse,
        );
      });
    });
  });
}
