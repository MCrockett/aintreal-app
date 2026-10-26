import 'package:shared_preferences/shared_preferences.dart';

/// The player's last Classic settings, used by the create screen and by
/// games started from the home pair (spec R7).
abstract class ClassicSettingsStore {
  static const _roundsKey = 'classic_rounds';
  static const _timeKey = 'classic_time_per_round';

  /// Options the create screen offers; anything else falls back to defaults.
  static const roundOptions = [4, 5, 6, 8, 10];
  static const timeOptions = [3, 5, 7, 10];

  static Future<({int rounds, int timePerRound})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rounds = prefs.getInt(_roundsKey);
    final time = prefs.getInt(_timeKey);
    return (
      rounds: roundOptions.contains(rounds) ? rounds! : 6,
      timePerRound: timeOptions.contains(time) ? time! : 5,
    );
  }

  static Future<void> save(int rounds, int timePerRound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roundsKey, rounds);
    await prefs.setInt(_timeKey, timePerRound);
  }
}
