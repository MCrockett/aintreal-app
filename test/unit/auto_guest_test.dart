import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/core/auth/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waits for the session to leave SessionLoading.
Future<SessionState> settle(ProviderContainer c) async {
  for (var i = 0; i < 50 && c.read(sessionProvider) is SessionLoading; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return c.read(sessionProvider);
}

ProviderContainer container() {
  final c = ProviderContainer(overrides: [authServiceProvider.overrideWithValue(null)]);
  addTearDown(c.dispose);
  c.listen(sessionProvider, (_, __) {});
  return c;
}

void main() {
  test('a fresh install starts as a guest, straight to the home pair', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await settle(container());
    expect(s, isA<SessionGuest>());
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('guest_name'), (s as SessionGuest).guestName);
    expect(prefs.getBool(autoGuestStartedKey), isTrue);
  });

  test('an existing guest keeps their name', () async {
    SharedPreferences.setMockInitialValues({'guest_name': 'CraftyPotato40'});
    final s = await settle(container());
    expect((s as SessionGuest).guestName, 'CraftyPotato40');
  });

  test('after the first automatic guest, no session means the sign-in screen', () async {
    SharedPreferences.setMockInitialValues({autoGuestStartedKey: true});
    expect(await settle(container()), isA<SessionNone>());
  });

  test('a guest who chooses to sign in reaches the sign-in screen', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await settle(c);
    await c.read(sessionProvider.notifier).endSession();
    expect(c.read(sessionProvider), isA<SessionNone>());
  });
}
