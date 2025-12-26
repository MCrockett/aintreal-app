// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Cache the detection result so we only check once.
bool? _needsNativeHtmlImagesCache;

/// Check if we need to use native HTML images.
/// Returns true for browsers without WebGL where CanvasKit falls back to CPU
/// and has issues with cross-origin images.
bool get _needsNativeHtmlImages {
  if (_needsNativeHtmlImagesCache != null) {
    return _needsNativeHtmlImagesCache!;
  }

  // Check if WebGL is available
  final canvas = html.CanvasElement();
  final hasWebGL = canvas.getContext('webgl2') != null ||
                   canvas.getContext('webgl') != null;

  // Use native HTML images when WebGL is not available
  // (CanvasKit CPU fallback has issues with cross-origin images)
  _needsNativeHtmlImagesCache = !hasWebGL;

  if (_needsNativeHtmlImagesCache!) {
    debugPrint('WebGL not available - using native HTML images for compatibility');
  }

  return _needsNativeHtmlImagesCache!;
}

/// Web implementation that uses Flutter's Image.network when possible,
/// falling back to native HTML img elements when WebGL is unavailable.
class WebImage extends StatefulWidget {
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
  State<WebImage> createState() => _WebImageState();
}

class _WebImageState extends State<WebImage> {
  late String _viewType;
  bool _isLoading = true;
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (_needsNativeHtmlImages) {
      _viewType = 'img-${widget.imageUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
      _registerViewFactory();
    }
  }

  @override
  void didUpdateWidget(WebImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_needsNativeHtmlImages && oldWidget.imageUrl != widget.imageUrl) {
      _viewType = 'img-${widget.imageUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
      _isLoading = true;
      _hasError = false;
      _error = null;
      _registerViewFactory();
    }
  }

  void _registerViewFactory() {
    // Register the view factory for this image
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        // Wrap img in a div to better control pointer events
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'none';

        final img = html.ImageElement()
          ..src = widget.imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _boxFitToCss(widget.fit)
          ..style.display = 'block'
          ..style.pointerEvents = 'none'
          ..crossOrigin = 'anonymous';

        container.append(img);

        img.onLoad.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
            });
          }
        });

        img.onError.listen((event) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _error = 'Failed to load image: ${widget.imageUrl}';
            });
          }
        });

        return container;
      },
    );
  }

  String _boxFitToCss(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
        return 'contain'; // Closest CSS equivalent
      case BoxFit.fitHeight:
        return 'contain'; // Closest CSS equivalent
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Flutter's native Image.network when WebGL is available
    if (!_needsNativeHtmlImages) {
      return Image.network(
        widget.imageUrl,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder?.call(context, widget.imageUrl) ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image load error for ${widget.imageUrl}: $error');
          return widget.errorWidget?.call(context, widget.imageUrl, error) ??
              const Center(child: Icon(Icons.error));
        },
      );
    }

    // Fallback to native HTML img element for browsers without WebGL
    if (_hasError && widget.errorWidget != null) {
      return widget.errorWidget!(context, widget.imageUrl, _error ?? 'Unknown error');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // The actual HTML img element - wrapped in IgnorePointer so
        // Flutter's gesture system handles taps on the parent widget
        IgnorePointer(
          child: HtmlElementView(viewType: _viewType),
        ),
        // Show placeholder while loading
        if (_isLoading && widget.placeholder != null)
          widget.placeholder!(context, widget.imageUrl),
        if (_isLoading && widget.placeholder == null)
          const Center(child: CircularProgressIndicator()),
        // Show error widget if loading failed
        if (_hasError && widget.errorWidget == null)
          const Center(child: Icon(Icons.error)),
      ],
    );
  }
}

/// Preload an image on web.
void preloadWebImage(String url) {
  if (_needsNativeHtmlImages) {
    // Use native browser loading for fallback mode
    final img = html.ImageElement()
      ..src = url
      ..crossOrigin = 'anonymous';
    img.onLoad.listen((_) {
      debugPrint('Preloaded image: $url');
    });
    img.onError.listen((_) {
      debugPrint('Failed to preload image: $url');
    });
  } else {
    // For normal mode, just log - Flutter's Image.network handles caching
    debugPrint('Preloaded image: $url');
  }
}
