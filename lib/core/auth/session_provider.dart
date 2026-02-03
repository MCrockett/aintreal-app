import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/guest_name_generator.dart';
import 'auth_provider.dart';

/// Session state representing how the user is playing.
sealed class SessionState {
  const SessionState();
}

/// Session not yet initialized (checking stored state).
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// User has not chosen how to play yet.
class SessionNone extends SessionState {
  const SessionNone();
}

/// User is playing as a guest.
class SessionGuest extends SessionState {
  const SessionGuest(this.guestName);
  final String guestName;
}

/// User is signed in with Firebase.
class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.displayName);
  final String displayName;
}

const _guestNameKey = 'guest_name';
const _testModeKey = 'test_mode';

/// Test mode provider - when enabled, player name is prefixed with ~ to exclude from stats.
class TestModeNotifier extends StateNotifier<bool> {
  TestModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_testModeKey) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool(_testModeKey, state);
  }
}

final testModeProvider = StateNotifierProvider<TestModeNotifier, bool>((ref) {
  return TestModeNotifier();
});

/// Notifier for managing session state.
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._ref) : super(const SessionLoading()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    // On web, skip Firebase auth - just use guest mode
    if (kIsWeb) {
      // Check for stored guest name on web
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedGuestName = prefs.getString(_guestNameKey);
        if (storedGuestName != null) {
          state = SessionGuest(storedGuestName);
          return;
        }
      } catch (e) {
        // SharedPreferences might fail on web in some contexts
      }
      // No stored guest name - go to sign-in screen
      state = const SessionNone();
      return;
    }

    // Mobile: Set up auth listener to catch Firebase session restoration.
    // fireImmediately ensures we process the current auth state even if
    // it was already resolved before this listener was registered.
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthStateAuthenticated) {
        state = SessionAuthenticated(next.displayName);
        _clearGuestName();
      } else if (next is AuthStateUnauthenticated) {
        // Only clear session if we were previously authenticated
        // Don't clear guest sessions when auth becomes unauthenticated
        if (state is SessionAuthenticated) {
          state = const SessionNone();
        } else if (state is SessionLoading) {
          // Auth finished loading as unauthenticated, check for guest
          _checkGuestSession();
        }
      }
    }, fireImmediately: true);
  }

  /// Check for stored guest session or set SessionNone.
  Future<void> _checkGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedGuestName = prefs.getString(_guestNameKey);
    if (storedGuestName != null) {
      state = SessionGuest(storedGuestName);
    } else {
      state = const SessionNone();
    }
  }

  /// Start a guest session with a generated or custom name.
  Future<void> startGuestSession([String? customName]) async {
    final guestName = customName ?? GuestNameGenerator.generate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestNameKey, guestName);
    state = SessionGuest(guestName);
  }

  /// End the current session (sign out or clear guest).
  Future<void> endSession() async {
    final currentState = state;
    if (currentState is SessionAuthenticated) {
      await _ref.read(authProvider.notifier).signOut();
    }
    await _clearGuestName();
    state = const SessionNone();
  }

  Future<void> _clearGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestNameKey);
  }

  /// Get the current player name (for game creation/joining).
  String? get playerName {
    final s = state;
    if (s is SessionGuest) return s.guestName;
    if (s is SessionAuthenticated) return s.displayName;
    return null;
  }
}

/// Provider for session state.
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});

/// Convenience provider for checking if user has an active session.
final hasSessionProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session is SessionGuest || session is SessionAuthenticated;
});

/// Convenience provider for getting the current player name.
/// Prepends ~ when test mode is enabled.
final playerNameProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  final testMode = ref.watch(testModeProvider);
  String? name;
  if (session is SessionGuest) name = session.guestName;
  if (session is SessionAuthenticated) name = session.displayName;
  if (name != null && testMode) return '~$name';
  return name;
});
