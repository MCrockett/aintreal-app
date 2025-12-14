import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available sound effects in the game.
enum GameSound {
  // Answer feedback
  correct,
  wrong,

  // Timer
  tick,
  timeUp,

  // Bonuses and rewards
  bonus,
  streak,

  // Game events
  roundStart,
  reveal,
  victory,
  gameOver,
}

/// Service for playing game sounds and haptic feedback.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _initialized = false;

  // Sound file paths (WAV for better cross-platform support)
  static const _soundPaths = <GameSound, String>{
    GameSound.correct: 'sounds/correct.wav',
    GameSound.wrong: 'sounds/wrong.wav',
    GameSound.tick: 'sounds/tick.wav',
    GameSound.timeUp: 'sounds/time_up.wav',
    GameSound.bonus: 'sounds/bonus.wav',
    GameSound.streak: 'sounds/streak.wav',
    GameSound.roundStart: 'sounds/round_start.wav',
    GameSound.reveal: 'sounds/reveal.wav',
    GameSound.victory: 'sounds/victory.wav',
    GameSound.gameOver: 'sounds/game_over.wav',
  };

  /// Initialize the sound service and load preferences.
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      _initialized = true;

      // Set low latency mode for quick sound playback
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('Failed to initialize SoundService: $e');
    }
  }

  /// Enable or disable sounds.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  /// Enable or disable haptic feedback.
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', enabled);
  }

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  /// Play a game sound effect.
  Future<void> play(GameSound sound) async {
    if (!_soundEnabled) return;

    try {
      final path = _soundPaths[sound];
      if (path != null) {
        await _player.play(AssetSource(path));
      }
    } catch (e) {
      // Sound file might not exist yet - fall back to haptic only
      debugPrint('Failed to play sound $sound: $e');
    }
  }

  /// Trigger haptic feedback.
  Future<void> haptic(HapticType type) async {
    if (!_hapticEnabled) return;

    try {
      switch (type) {
        case HapticType.light:
          await HapticFeedback.lightImpact();
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
        case HapticType.selection:
          await HapticFeedback.selectionClick();
        case HapticType.success:
          // Double light impact for success
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
        case HapticType.error:
          await HapticFeedback.heavyImpact();
        case HapticType.warning:
          await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Failed to trigger haptic: $e');
    }
  }

  /// Play sound with accompanying haptic feedback.
  Future<void> playWithHaptic(GameSound sound, HapticType hapticType) async {
    await Future.wait([
      play(sound),
      haptic(hapticType),
    ]);
  }

  /// Play correct answer feedback.
  Future<void> playCorrect() async {
    await playWithHaptic(GameSound.correct, HapticType.success);
  }

  /// Play wrong answer feedback.
  Future<void> playWrong() async {
    await playWithHaptic(GameSound.wrong, HapticType.error);
  }

  /// Play countdown tick.
  Future<void> playTick() async {
    await playWithHaptic(GameSound.tick, HapticType.light);
  }

  /// Play time up warning.
  Future<void> playTimeUp() async {
    await playWithHaptic(GameSound.timeUp, HapticType.warning);
  }

  /// Play bonus award sound.
  Future<void> playBonus() async {
    await playWithHaptic(GameSound.bonus, HapticType.medium);
  }

  /// Play streak bonus sound.
  Future<void> playStreak() async {
    await playWithHaptic(GameSound.streak, HapticType.success);
  }

  /// Play round start sound.
  Future<void> playRoundStart() async {
    await playWithHaptic(GameSound.roundStart, HapticType.medium);
  }

  /// Play reveal sound.
  Future<void> playReveal() async {
    await playWithHaptic(GameSound.reveal, HapticType.medium);
  }

  /// Play victory sound.
  Future<void> playVictory() async {
    await playWithHaptic(GameSound.victory, HapticType.heavy);
  }

  /// Play game over sound.
  Future<void> playGameOver() async {
    await playWithHaptic(GameSound.gameOver, HapticType.medium);
  }

  /// Stop any currently playing sound.
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose of resources.
  void dispose() {
    _player.dispose();
  }
}

/// Types of haptic feedback.
enum HapticType {
  light,
  medium,
  heavy,
  selection,
  success,
  error,
  warning,
}

/// Provider for sound service.
final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService.instance;
});
