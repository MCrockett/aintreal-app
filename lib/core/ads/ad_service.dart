import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing AdMob ads.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  /// Test Ad Unit IDs (replace with real IDs for production)
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  /// Get the appropriate banner ad unit ID for the platform.
  String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }
    // TODO: Replace with production ad unit IDs
    if (Platform.isAndroid) {
      return _testBannerAdUnitId; // Replace with Android production ID
    } else if (Platform.isIOS) {
      return _testBannerAdUnitId; // Replace with iOS production ID
    }
    return _testBannerAdUnitId;
  }

  /// Get the appropriate interstitial ad unit ID for the platform.
  String get interstitialAdUnitId {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    }
    // TODO: Replace with production ad unit IDs
    if (Platform.isAndroid) {
      return _testInterstitialAdUnitId; // Replace with Android production ID
    } else if (Platform.isIOS) {
      return _testInterstitialAdUnitId; // Replace with iOS production ID
    }
    return _testInterstitialAdUnitId;
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Initialize the Mobile Ads SDK.
  Future<void> init() async {
    if (kIsWeb) return;

    await MobileAds.instance.initialize();
    debugPrint('AdMob initialized');

    // Pre-load interstitial ad
    loadInterstitialAd();
  }

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
        },
      ),
    );
  }

  /// Show an interstitial ad if available.
  /// Returns true if the ad was shown, false otherwise.
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      loadInterstitialAd();
      return false;
    }

    await _interstitialAd!.show();
    return true;
  }

  /// Check if an interstitial ad is ready to show.
  bool get isInterstitialReady => _interstitialAd != null;

  /// Dispose of all ads.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
