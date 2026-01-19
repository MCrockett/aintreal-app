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

    // Mobile: Set up auth listener FIRST to catch Firebase session restoration
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
    });

    // Check current auth state (might already be loaded)
    final authState = _ref.read(authProvider);

    if (authState is AuthStateAuthenticated) {
      state = SessionAuthenticated(authState.displayName);
      return;
    }

    if (authState is AuthStateUnauthenticated) {
      // Auth already loaded and user not signed in - check for guest
      await _checkGuestSession();
      return;
    }

    // Auth is still loading - stay in SessionLoading until listener fires
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
final playerNameProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is SessionGuest) return session.guestName;
  if (session is SessionAuthenticated) return session.displayName;
  return null;
});
