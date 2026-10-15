import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/features/home/home_screen.dart';
import 'package:aintreal_app/widgets/how_to_play_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app() => ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(null)],
        child: MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );

  testWidgets('first launch opens How to Play and remembers it', (tester) async {
    SharedPreferences.setMockInitialValues({'guest_name': 'TestPlayer'});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(HowToPlayDialog), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(howToPlaySeenKey), isTrue);
  });

  testWidgets('later launches do not open it', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'guest_name': 'TestPlayer', howToPlaySeenKey: true});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(HowToPlayDialog), findsNothing);
  });
}
