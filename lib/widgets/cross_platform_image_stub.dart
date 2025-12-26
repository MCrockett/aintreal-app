import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms.
/// This file is used when dart.library.html is not available.

class WebImage extends StatelessWidget {
  const WebImage({
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
    // This should never be called on non-web platforms
    throw UnsupportedError('WebImage is only supported on web platforms');
  }
}

void preloadWebImage(String url) {
  // No-op on non-web platforms
}
