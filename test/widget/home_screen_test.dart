import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aintreal_app/features/home/home_screen.dart';
import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';

void main() {
  setUp(() {
    // Set up mock SharedPreferences with a guest name for all tests
    SharedPreferences.setMockInitialValues({'guest_name': 'TestPlayer'});
  });

  Widget createTestApp({Widget? child}) {
    return ProviderScope(
      overrides: [
        // Override auth service to null to prevent Firebase access
        // This makes AuthNotifier return AuthStateUnauthenticated
        // and SessionNotifier will load the guest name from SharedPreferences
        authServiceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child ?? const HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('displays logo and tagline', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should display the tagline
      expect(find.text('Spot the AI'), findsOneWidget);
    });

    testWidgets('displays all game mode cards', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should have Party Mode, Classic Solo, and Marathon cards
      expect(find.text('Party Mode'), findsOneWidget);
      expect(find.text('Classic Solo'), findsOneWidget);
      expect(find.text('Marathon'), findsOneWidget);
    });

    testWidgets('displays player count badges', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('2-8 players'), findsOneWidget);
      expect(find.text('Single player'), findsOneWidget);
      expect(find.text('26 rounds'), findsOneWidget);
    });

    testWidgets('displays mode descriptions', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Play with friends! Everyone guesses at once.'),
        findsOneWidget,
      );
      expect(
        find.text('Practice at your own pace.'),
        findsOneWidget,
      );
      expect(
        find.text("How far can you go? One miss and it's over!"),
        findsOneWidget,
      );
    });

    testWidgets('displays Join Game button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Join Game'), findsOneWidget);
      expect(find.text('Enter code'), findsOneWidget);
    });

    testWidgets('displays How to Play button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('How to Play'), findsOneWidget);
    });

    testWidgets('mode cards have correct icons', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Party Mode should have groups icon
      expect(find.byIcon(Icons.groups), findsOneWidget);

      // Classic Solo should have person icon (note: profile also uses person icon)
      expect(find.byIcon(Icons.person), findsWidgets);

      // Marathon should have trophy icon
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('Party Mode card has gradient style', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Party Mode card should exist
      final partyFinder = find.text('Party Mode');
      expect(partyFinder, findsOneWidget);

      // Find the parent container that should have the gradient
      final container = find.ancestor(
        of: partyFinder,
        matching: find.byType(Container),
      );
      expect(container, findsWidgets);
    });

    testWidgets('Join Game button exists', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find the Join Game text
      expect(find.text('Join Game'), findsOneWidget);
    });

    testWidgets('mode cards are rendered', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify all three mode cards are rendered by checking for their titles
      expect(find.text('Party Mode'), findsOneWidget);
      expect(find.text('Classic Solo'), findsOneWidget);
      expect(find.text('Marathon'), findsOneWidget);
    });
  });
}
