import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/utils/guest_name_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('publicPlayerName', () {
    test('uses the display name when there is one', () {
      expect(publicPlayerName(displayName: 'Sky', uid: 'u1'), 'Sky');
      expect(publicPlayerName(displayName: '  Sky  ', uid: 'u1'), 'Sky');
    });

    test('never returns an email', () {
      for (final name in [null, '', '   ', 'abc@privaterelay.appleid.com']) {
        final result = publicPlayerName(displayName: name, uid: 'uid-123');
        expect(result, isNot(contains('@')));
        expect(result, GuestNameGenerator.forSeed('uid-123'));
      }
    });
  });

  group('GuestNameGenerator.forSeed', () {
    test('is stable for a seed and varies across seeds', () {
      expect(GuestNameGenerator.forSeed('abc'), GuestNameGenerator.forSeed('abc'));
      final names = {for (var i = 0; i < 50; i++) GuestNameGenerator.forSeed('uid$i')};
      expect(names.length, greaterThan(40));
    });

    test('matches the guest name format', () {
      expect(GuestNameGenerator.forSeed('xyz'), matches(RegExp(r'^[A-Z][a-z]+[A-Z][a-z]+\d{2}$')));
    });
  });
}
