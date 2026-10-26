import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';
import 'package:aintreal_app/core/storage/classic_settings_store.dart';
import 'package:aintreal_app/features/lobby/create_game_screen.dart';
import 'package:aintreal_app/models/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Labels of the selected option chips, top to bottom (rounds, then time).
List<String> selectedOptions(WidgetTester tester) => tester
    .widgetList(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_OptionChip'))
    .where((w) => (w as dynamic).isSelected as bool)
    .map((w) => (w as dynamic).label as String)
    .toList();

Widget screen({int? rounds, int? time}) => ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(null)],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: CreateGameScreen(mode: GameMode.classic, initialRounds: rounds, initialTimePerRound: time),
      ),
    );

void main() {
  test('defaults are 6 rounds and 5 seconds', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ClassicSettingsStore.load(), (rounds: 6, timePerRound: 5));
  });

  test('save then load', () async {
    SharedPreferences.setMockInitialValues({});
    await ClassicSettingsStore.save(10, 7);
    expect(await ClassicSettingsStore.load(), (rounds: 10, timePerRound: 7));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('classic_rounds'), 10);
    expect(prefs.getInt('classic_time_per_round'), 7);
  });

  test('values the create screen no longer offers fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({'classic_rounds': 99, 'classic_time_per_round': 8});
    expect(await ClassicSettingsStore.load(), (rounds: 6, timePerRound: 5));
  });

  testWidgets('Classic create screen starts with the saved settings', (tester) async {
    SharedPreferences.setMockInitialValues({'guest_name': 'P', 'classic_rounds': 10, 'classic_time_per_round': 7});
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(selectedOptions(tester), ['10', '7']);
  });

  testWidgets('route extras still win over saved settings', (tester) async {
    SharedPreferences.setMockInitialValues({'guest_name': 'P', 'classic_rounds': 10, 'classic_time_per_round': 7});
    await tester.pumpWidget(screen(rounds: 4, time: 3));
    await tester.pumpAndSettle();
    expect(selectedOptions(tester), ['4', '3']);
  });
}
