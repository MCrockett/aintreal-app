import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads/ad_service.dart';

/// Widget that displays a banner ad.
/// Shows nothing on web or if the ad fails to load.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    // Listen for ad removal purchase to hide banner immediately
    AdService.instance.adsEnabledNotifier.addListener(_onAdsEnabledChanged);
  }

  void _onAdsEnabledChanged() {
    if (!AdService.instance.adsEnabledNotifier.value) {
      // Ads were disabled (user purchased removal)
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) {
        setState(() => _isLoaded = false);
      }
    }
  }

  void _loadAd() {
    // Skip on web or if ads are disabled (user purchased removal)
    if (kIsWeb || !AdService.instance.adsEnabled) return;

    // Don't load if already loading or loaded
    if (_isLoading || _bannerAd != null) return;

    _isLoading = true;

    _bannerAd = AdService.instance.createBannerAd(
      onAdLoaded: (ad) {
        _isLoading = false;
        if (_isDisposed) {
          ad.dispose();
          return;
        }
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onAdFailedToLoad: (ad, error) {
        _isLoading = false;
        debugPrint('Banner ad failed to load: $error');
        ad.dispose();
        // Clear reference so we don't try to use disposed ad
        if (mounted) {
          setState(() => _bannerAd = null);
        } else {
          _bannerAd = null;
        }
      },
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    AdService.instance.adsEnabledNotifier.removeListener(_onAdsEnabledChanged);
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything on web
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // If ads are disabled (purchased removal), don't reserve space
    if (!AdService.instance.adsEnabled) {
      return const SizedBox.shrink();
    }

    // Standard banner height is 50px - always reserve this space to prevent layout jump
    const bannerHeight = 50.0;

    if (!_isLoaded || _bannerAd == null) {
      // Reserve space while loading to prevent layout shift
      return const SizedBox(height: bannerHeight);
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
