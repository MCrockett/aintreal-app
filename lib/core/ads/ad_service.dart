import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing AdMob ads with frequency control.
///
/// Interstitial ad frequency:
/// - No ads for first 5 games (let users get hooked)
/// - Show after 5th game
/// - Then show every 3rd game after that
/// - Maximum 1 ad per 5 minutes
/// - Skip all ads if user purchased ad removal
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // Storage keys
  static const _gamesPlayedKey = 'ad_games_played';
  static const _lastAdShownKey = 'ad_last_shown_timestamp';
  static const _adRemovalKey = 'ad_removal_purchased';

  // Frequency settings
  static const _firstAdAfterGames = 5; // Show first ad after 5th game
  static const _adEveryNGames = 3; // Then every 3rd game
  static const _minSecondsBetweenAds = 300; // 5 minutes = 300 seconds

  /// Test Ad Unit IDs (used in debug mode)
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Production Ad Unit IDs
  /// Android IDs configured. iOS IDs needed for App Store launch.
  static const _prodAndroidBannerAdUnitId =
      'ca-app-pub-3930486883953215/8771045412';
  static const _prodAndroidInterstitialAdUnitId =
      'ca-app-pub-3930486883953215/1028480288';
  static const _prodIosBannerAdUnitId = 'ca-app-pub-3930486883953215/7654589037';
  static const _prodIosInterstitialAdUnitId =
      'ca-app-pub-3930486883953215/9191866130';

  // State
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _gamesPlayed = 0;
  DateTime? _lastAdShown;
  bool _adRemovalPurchased = false;
  SharedPreferences? _prefs;

  /// Notifier for ads enabled state. Widgets can listen to this to react
  /// immediately when ad removal is purchased.
  final ValueNotifier<bool> adsEnabledNotifier = ValueNotifier(true);

  /// Get the appropriate banner ad unit ID for the platform.
  String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }
    if (Platform.isAndroid) {
      return _prodAndroidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _prodIosBannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  /// Get the appropriate interstitial ad unit ID for the platform.
  String get interstitialAdUnitId {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    }
    if (Platform.isAndroid) {
      return _prodAndroidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _prodIosInterstitialAdUnitId;
    }
    return _testInterstitialAdUnitId;
  }

  /// Whether ads are enabled (not purchased ad removal).
  bool get adsEnabled => !_adRemovalPurchased;

  /// Number of games played (for frequency tracking).
  int get gamesPlayed => _gamesPlayed;

  /// Initialize the Mobile Ads SDK and load state.
  Future<void> init() async {
    if (kIsWeb) return;

    // Load persisted state
    _prefs = await SharedPreferences.getInstance();
    _gamesPlayed = _prefs?.getInt(_gamesPlayedKey) ?? 0;
    _adRemovalPurchased = _prefs?.getBool(_adRemovalKey) ?? false;
    adsEnabledNotifier.value = !_adRemovalPurchased;

    final lastAdTimestamp = _prefs?.getInt(_lastAdShownKey);
    if (lastAdTimestamp != null) {
      _lastAdShown = DateTime.fromMillisecondsSinceEpoch(lastAdTimestamp);
    }

    debugPrint(
        'AdService: games=$_gamesPlayed, adsEnabled=$adsEnabled, lastAd=$_lastAdShown');

    // Request App Tracking Transparency authorization on iOS
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('ATT status: $status');
    }

    await MobileAds.instance.initialize();
    debugPrint('AdMob initialized');

    // Pre-load interstitial ad if ads are enabled
    if (adsEnabled) {
      loadInterstitialAd();
    }
  }

  /// Record that a game was completed. Call this when a game ends.
  Future<void> recordGameCompleted() async {
    _gamesPlayed++;
    await _prefs?.setInt(_gamesPlayedKey, _gamesPlayed);
    debugPrint('AdService: Game completed, total=$_gamesPlayed, interstitialReady=$isInterstitialReady');

    // Ensure an interstitial is loaded for when we need it
    if (adsEnabled && _interstitialAd == null && !_isInterstitialLoading) {
      loadInterstitialAd();
    }
  }

  /// Check if an interstitial ad should be shown based on frequency rules.
  bool shouldShowInterstitial() {
    // Never show if ads removed
    if (_adRemovalPurchased) {
      debugPrint('AdService: Ads removed, skipping');
      return false;
    }

    // Never show if ad not ready
    if (_interstitialAd == null) {
      debugPrint('AdService: Ad not ready');
      return false;
    }

    // Don't show for first N games
    if (_gamesPlayed < _firstAdAfterGames) {
      debugPrint(
          'AdService: Only $_gamesPlayed games, need $_firstAdAfterGames');
      return false;
    }

    // Check 5-minute frequency cap
    if (_lastAdShown != null) {
      final secondsSinceLastAd =
          DateTime.now().difference(_lastAdShown!).inSeconds;
      if (secondsSinceLastAd < _minSecondsBetweenAds) {
        debugPrint(
            'AdService: Only ${secondsSinceLastAd}s since last ad, need $_minSecondsBetweenAds');
        return false;
      }
    }

    // After first threshold, show every Nth game
    // Games 5, 8, 11, 14... (5th, then every 3rd)
    final gamesSinceFirstAd = _gamesPlayed - _firstAdAfterGames;
    final shouldShow = gamesSinceFirstAd % _adEveryNGames == 0;

    debugPrint(
        'AdService: games=$_gamesPlayed, sinceFirst=$gamesSinceFirstAd, shouldShow=$shouldShow');
    return shouldShow;
  }

  /// Show an interstitial ad if frequency rules allow.
  /// Call this after game completion (e.g., when user clicks "New Game").
  /// Returns true if the ad was shown, false otherwise.
  Future<bool> showInterstitialIfEligible() async {
    debugPrint('AdService: showInterstitialIfEligible called, games=$_gamesPlayed');
    if (!shouldShowInterstitial()) {
      return false;
    }

    return await _showInterstitialAd();
  }

  /// Force show an interstitial ad (bypasses frequency check).
  /// Use sparingly - prefer showInterstitialIfEligible().
  Future<bool> showInterstitialAd() async {
    if (_adRemovalPurchased) return false;
    return await _showInterstitialAd();
  }

  Future<bool> _showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      loadInterstitialAd();
      return false;
    }

    // Record ad shown time
    _lastAdShown = DateTime.now();
    await _prefs?.setInt(_lastAdShownKey, _lastAdShown!.millisecondsSinceEpoch);

    await _interstitialAd!.show();
    return true;
  }

  /// Set ad removal purchase state. Call when IAP completes.
  Future<void> setAdRemovalPurchased(bool purchased) async {
    _adRemovalPurchased = purchased;
    await _prefs?.setBool(_adRemovalKey, purchased);
    debugPrint('AdService: Ad removal purchased=$purchased');

    // Notify listeners immediately so UI can update
    adsEnabledNotifier.value = !purchased;

    // Dispose interstitial if ads removed
    if (purchased) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  /// Check if ad removal was purchased.
  bool get isAdRemovalPurchased => _adRemovalPurchased;

  /// Create a banner ad.
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );
  }

  /// Load an interstitial ad.
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    if (_adRemovalPurchased) return; // Don't load if ads removed

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              // Pre-load the next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialLoading = false;
          // Retry after 60 seconds
          Future.delayed(const Duration(seconds: 60), () {
            if (_interstitialAd == null && !_isInterstitialLoading && adsEnabled) {
              loadInterstitialAd();
            }
          });
        },
      ),
    );
  }

  /// Check if an interstitial ad is ready to show.
  bool get isInterstitialReady => _interstitialAd != null;

  /// Dispose of all ads.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
