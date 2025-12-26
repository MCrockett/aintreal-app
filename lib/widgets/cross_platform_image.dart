import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/env.dart';

// Conditional import for web-specific code
import 'cross_platform_image_stub.dart'
    if (dart.library.html) 'cross_platform_image_web.dart' as platform;

/// A cross-platform network image widget that works on web and mobile.
///
/// On web, uses native HTML img elements via HtmlElementView for better
/// cross-origin compatibility (bypasses CanvasKit rendering issues).
/// On mobile, uses [CachedNetworkImage] for caching benefits.
class CrossPlatformImage extends StatelessWidget {
  const CrossPlatformImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, Object error)?
      errorWidget;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Use native HTML img element on web to bypass CanvasKit rendering issues
      return platform.WebImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }

    // Use CachedNetworkImage on mobile for caching
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      httpHeaders: const {'X-Mobile-App': Env.mobileAppSecret},
      placeholder: placeholder != null
          ? (context, url) => placeholder!(context, url)
          : null,
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!(context, url, error)
          : null,
    );
  }
}

/// A provider for preloading images on both web and mobile.
class CrossPlatformImageProvider {
  /// Preload an image into the cache.
  static Future<void> preload(BuildContext context, String url) async {
    if (kIsWeb) {
      // On web, preload using native browser
      platform.preloadWebImage(url);
    } else {
      // On mobile, use CachedNetworkImageProvider with auth header
      await precacheImage(
        CachedNetworkImageProvider(
          url,
          headers: const {'X-Mobile-App': Env.mobileAppSecret},
        ),
        context,
      );
    }
  }
}
