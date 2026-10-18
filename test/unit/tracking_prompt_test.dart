import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/ads/ad_service.dart';

void main() {
  group('AdService.shouldRequestTracking', () {
    test('asks only while undecided', () {
      expect(
          AdService.shouldRequestTracking(
              status: TrackingStatus.notDetermined, adRemovalPurchased: false),
          isTrue);
      for (final status in [
        TrackingStatus.authorized,
        TrackingStatus.denied,
        TrackingStatus.restricted,
        TrackingStatus.notSupported,
      ]) {
        expect(
            AdService.shouldRequestTracking(
                status: status, adRemovalPurchased: false),
            isFalse,
            reason: '$status');
      }
    });

    test('never asks after ad removal', () {
      expect(
          AdService.shouldRequestTracking(
              status: TrackingStatus.notDetermined, adRemovalPurchased: true),
          isFalse);
    });
  });
}
