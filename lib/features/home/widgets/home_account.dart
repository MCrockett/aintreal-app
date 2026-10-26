import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/session_provider.dart';

/// Sign-in from home, the same calls the sign-in screen makes. Overridden in
/// tests, which have no Firebase.
class HomeSignIn {
  const HomeSignIn(this._ref);

  final Ref _ref;

  /// Apple sign-in is offered on iOS only, as on the sign-in screen.
  bool get appleAvailable => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> google() => _ref.read(authProvider.notifier).signInWithGoogle();
  Future<void> apple() => _ref.read(authProvider.notifier).signInWithApple();
}

final homeSignInProvider = Provider<HomeSignIn>((ref) => HomeSignIn(ref));

/// The signed-in player's stats, from the profile endpoint the Profile
/// screen uses. Null when there is no signed-in player or the call fails.
final homeStatsProvider = FutureProvider.autoDispose<UserStats?>((ref) async {
  if (ref.watch(sessionProvider) is! SessionAuthenticated) return null;
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return null;
    return (await AuthApi.instance.getProfile(idToken)).stats;
  } catch (_) {
    return null;
  }
});

/// Bottom of home: a sign-in card for guests, a stats strip once signed in.
class HomeAccount extends ConsumerWidget {
  const HomeAccount({super.key, this.compact = false});

  /// Short screens get the one-row sign-in card.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    final session = ref.watch(sessionProvider);
    if (session is SessionGuest) return HomeSignInCard(guestName: session.guestName, compact: compact);
    if (session is SessionAuthenticated) {
      return HomePlayerStrip(
        name: session.displayName,
        stats: ref.watch(homeStatsProvider).valueOrNull,
        onTap: () => context.push(AppRoutes.profile),
      );
    }
    return const SizedBox.shrink();
  }
}

class HomeSignInCard extends ConsumerStatefulWidget {
  const HomeSignInCard({super.key, required this.guestName, this.compact = false});

  final String guestName;
  final bool compact;

  @override
  ConsumerState<HomeSignInCard> createState() => _HomeSignInCardState();
}

class _HomeSignInCardState extends ConsumerState<HomeSignInCard> {
  bool _pending = false;
  bool _failed = false;

  Future<void> _run(Future<void> Function() signIn) async {
    setState(() {
      _pending = true;
      _failed = false;
    });
    try {
      // On success the session becomes signed in and this card is replaced
      await signIn();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signIn = ref.watch(homeSignInProvider);
    final apple = signIn.appleAvailable;
    final google = _ProviderButton(
      key: const ValueKey('home-sign-in-google'),
      label: apple || widget.compact ? 'Google' : 'Continue with Google',
      icon: const _GoogleMark(),
      background: Colors.white,
      foreground: Colors.black87,
      onPressed: _pending ? null : () => _run(signIn.google),
    );
    final appleButton = _ProviderButton(
      key: const ValueKey('home-sign-in-apple'),
      label: 'Apple',
      icon: const Icon(Icons.apple, size: 20, color: Colors.white),
      background: Colors.black,
      foreground: Colors.white,
      onPressed: _pending ? null : () => _run(signIn.apple),
    );
    if (widget.compact) {
      return _Panel(
        key: const ValueKey('home-sign-in'),
        padding: 10,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _failed ? "Sign-in didn't finish. Try again." : 'Sign in to save your stats',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _failed ? AppTheme.wrongAnswer : null),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 100, child: google),
            if (apple) ...[const SizedBox(width: 8), SizedBox(width: 88, child: appleButton)],
          ],
        ),
      );
    }
    return _Panel(
      key: const ValueKey('home-sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Save your stats and streaks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            _failed ? "Sign-in didn't finish. Try again." : "You're playing as ${widget.guestName}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: _failed ? AppTheme.wrongAnswer : AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: google),
              if (apple) ...[const SizedBox(width: 10), Expanded(child: appleButton)],
            ],
          ),
        ],
      ),
    );
  }
}

/// Signed-in player: name and stats; tapping opens Profile.
class HomePlayerStrip extends StatelessWidget {
  const HomePlayerStrip({super.key, required this.name, required this.stats, required this.onTap});

  final String name;
  final UserStats? stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final games = s == null ? 0 : s.party.games + s.solo.games + s.marathon.attempts;
    final answered = s == null ? 0 : s.party.answered + s.solo.answered;
    final correct = s == null ? 0 : s.party.correct + s.solo.correct;
    return GestureDetector(
      key: const ValueKey('home-player'),
      onTap: onTap,
      child: _Panel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary,
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    s == null ? 'Your stats' : '$games ${games == 1 ? 'game' : 'games'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (answered > 0) _Stat(value: '${(correct * 100 / answered).round()}%', label: 'correct'),
            if (s != null && s.marathon.attempts > 0) ...[
              const SizedBox(width: 16),
              _Stat(value: '${s.marathon.bestStreak}', label: 'marathon'),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()])),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      );
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.child, this.padding = 14});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.secondary),
        ),
        child: child,
      );
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withValues(alpha: 0.6),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: foreground)),
              ),
            ],
          ),
        ),
      );
}

/// Google "G", drawn like the sign-in screen's.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Text(
        'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
              stops: [0.0, 0.33, 0.66, 1.0],
            ).createShader(const Rect.fromLTWH(0, 0, 18, 18)),
        ),
      );
}
