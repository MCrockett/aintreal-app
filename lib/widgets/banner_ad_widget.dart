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

    _bannerAd = AdService.instance.createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Banner ad failed to load: $error');
        ad.dispose();
      },
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    AdService.instance.adsEnabledNotifier.removeListener(_onAdsEnabledChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
