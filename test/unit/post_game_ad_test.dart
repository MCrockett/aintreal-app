import 'package:aintreal_app/core/ads/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The party host's screen is often the shared one (a TV, a projector, the
/// phone passed around), so a full-screen ad there interrupts everyone.
void main() {
  group('AdService.allowsPostGameInterstitial', () {
    test('skips the party host', () {
      expect(
        AdService.allowsPostGameInterstitial(mode: 'party', isHost: true),
        isFalse,
      );
    });

    test('allows party guests', () {
      expect(
        AdService.allowsPostGameInterstitial(mode: 'party', isHost: false),
        isTrue,
      );
    });

    test('allows solo modes (the player is always the host)', () {
      for (final mode in ['classic', 'marathon']) {
        expect(
          AdService.allowsPostGameInterstitial(mode: mode, isHost: true),
          isTrue,
          reason: mode,
        );
      }
    });

    test('treats an unknown mode as party (matches _parseGameMode)', () {
      expect(
        AdService.allowsPostGameInterstitial(mode: null, isHost: true),
        isFalse,
      );
    });
  });
}
