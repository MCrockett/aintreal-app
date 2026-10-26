import 'package:aintreal_app/config/env.dart';
import 'package:aintreal_app/features/home/widgets/home_pair_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home pair images send the mobile app header the image route requires', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final widget = container.read(pairImageBuilderProvider)('https://example.com/a.jpg', () {}, () {});

    expect(widget, isA<CachedNetworkImage>());
    final headers = (widget as CachedNetworkImage).httpHeaders;
    expect(headers?['X-Mobile-App'], Env.mobileAppSecret);
    expect(Env.mobileAppSecret, isNotEmpty);
  });
}
