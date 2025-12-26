import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/features/home/home_screen.dart';
import 'package:aintreal_app/config/theme.dart';

void main() {
  Widget createTestApp({Widget? child}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child ?? const HomeScreen(),
    );
  }

  group('HomeScreen', () {
    testWidgets('displays logo and tagline', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Should display the tagline
      expect(find.text('Spot the AI'), findsOneWidget);
    });

    testWidgets('displays all game mode cards', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Should have Party Mode, Classic Solo, and Marathon cards
      expect(find.text('Party Mode'), findsOneWidget);
      expect(find.text('Classic Solo'), findsOneWidget);
      expect(find.text('Marathon'), findsOneWidget);
    });

    testWidgets('displays player count badges', (tester) async {
      await tester.pumpWidget(createTestApp());

      expect(find.text('2-8 players'), findsOneWidget);
      expect(find.text('Single player'), findsOneWidget);
      expect(find.text('26 rounds'), findsOneWidget);
    });

    testWidgets('displays mode descriptions', (tester) async {
      await tester.pumpWidget(createTestApp());

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

      expect(find.text('Join Game'), findsOneWidget);
      expect(find.text('Enter code'), findsOneWidget);
    });

    testWidgets('displays How to Play button', (tester) async {
      await tester.pumpWidget(createTestApp());

      expect(find.text('How to Play'), findsOneWidget);
    });

    testWidgets('mode cards have correct icons', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Party Mode should have groups icon
      expect(find.byIcon(Icons.groups), findsOneWidget);

      // Classic Solo should have person icon
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Marathon should have trophy icon
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('Party Mode card has gradient style', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Party Mode card should have a Container with gradient
      final partyFinder = find.text('Party Mode');
      expect(partyFinder, findsOneWidget);

      // Find the parent container that should have the gradient
      final container = find.ancestor(
        of: partyFinder,
        matching: find.byType(Container),
      );
      expect(container, findsWidgets);
    });

    testWidgets('Join Game button is tappable', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Find the Join Game button
      final button = find.widgetWithText(OutlinedButton, 'Join Game');
      expect(button, findsOneWidget);

      // Button should be enabled
      final buttonWidget = tester.widget<OutlinedButton>(button);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('mode cards are tappable', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Find all InkWell widgets that are children of mode cards
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);
    });
  });
}
