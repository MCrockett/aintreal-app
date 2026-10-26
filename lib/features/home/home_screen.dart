import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/env.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/ads/ad_service.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/auth/session_provider.dart';
import '../../core/storage/classic_settings_store.dart';
import '../../models/game.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/how_to_play_dialog.dart';
import '../../widgets/logo.dart';
import 'home_game_starter.dart';
import 'home_pair_controller.dart';
import 'widgets/home_pair_view.dart';
import 'widgets/mode_row.dart';

/// Home screen: opens on a pair to guess (guess on open), with the game modes
/// underneath and profile, How to Play and settings in the menu.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver, RouteAware {
  int _tapCount = 0;
  String _version = '';
  bool _nextPending = false;
  late final HomePairController _pair;

  @override
  void initState() {
    super.initState();
    _pair = ref.read(homePairProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) _pair.load();
      // The pair is the first-launch instruction now; How to Play lives in
      // the menu.
      AdService.instance.requestTrackingIfNeeded();
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        final v = info.version;
        final b = info.buildNumber;
        if (v.isNotEmpty && b.isNotEmpty) {
          setState(() => _version = 'v$v+$b');
        } else {
          // Web fallback: PackageInfo returns empty on web
          setState(() => _version = 'v${Env.appVersion}');
        }
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _version = 'v${Env.appVersion}');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) homeRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    homeRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    // Route and dispose callbacks run while the navigator builds, when
    // providers can't change; the controller acts a moment later.
    Future.microtask(_pair.leave);
    super.dispose();
  }

  // Another screen covered home: drop anything in flight.
  @override
  void didPushNext() => Future.microtask(_pair.leave);

  // Home is visible again: a fresh pair (spec R3).
  @override
  void didPopNext() {
    if (!kIsWeb) Future.microtask(_pair.load);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _pair.onResume(DateTime.now());
  }

  /// Next pair: a Classic game whose round 1 is the home guess (spec R5).
  Future<void> _startFromHome() async {
    final s = ref.read(homePairProvider);
    final token = s.result?.resultToken;
    if (_nextPending || token == null) return;
    setState(() => _nextPending = true);
    // The player may leave home before create answers; then nothing happens.
    final loadId = s.loadId;
    final starter = ref.read(homeGameStarterProvider);
    final analytics = ref.read(homeAnalyticsProvider);
    final playerName = ref.read(playerNameProvider) ?? 'Player';
    final messenger = ScaffoldMessenger.of(context);
    String? failure;
    try {
      final saved = await ClassicSettingsStore.load();
      final config = GameConfig(rounds: saved.rounds, timePerRound: saved.timePerRound, mode: GameMode.classic);
      final res = await starter.start(playerName: playerName, config: config, firstRoundToken: token);
      await ClassicSettingsStore.save(saved.rounds, saved.timePerRound);
      analytics.gameStarted(carried: res.firstRound == 'applied');
      if (!mounted || !_pair.isCurrent(loadId)) return;
      context.go('/lobby/${res.code}', extra: {
        'playerName': playerName,
        'playerId': res.playerId,
        'isHost': true,
        'config': config.toJson(),
        'isSoloMode': true,
      });
    } on ApiException catch (e) {
      failure = e.message;
    } catch (_) {
      failure = 'Failed to create game. Please try again.';
    } finally {
      if (mounted) setState(() => _nextPending = false);
    }
    if (failure != null && mounted && _pair.isCurrent(loadId)) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  void _handleSubtitleTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      final wasOn = ref.read(testModeProvider);
      ref.read(testModeProvider.notifier).toggle();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasOn ? 'Test mode OFF' : 'Test mode ON'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _openMenu() {
    final session = ref.read(sessionProvider);
    final testMode = ref.read(testModeProvider);
    final hasProfile = session is SessionGuest || session is SessionAuthenticated;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.backgroundLight,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(hasProfile ? Icons.person : Icons.login),
              title: Text(hasProfile ? 'Profile & settings' : 'Sign in'),
              subtitle: switch (session) {
                SessionGuest(:final guestName) => Text(guestName),
                SessionAuthenticated(:final displayName) => Text(displayName),
                _ => null,
              },
              onTap: () {
                Navigator.pop(sheet);
                context.push(hasProfile ? AppRoutes.profile : AppRoutes.signIn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('How to Play'),
              onTap: () {
                Navigator.pop(sheet);
                showHowToPlayDialog(context);
              },
            ),
            if (testMode && _version.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_version, style: const TextStyle(color: AppTheme.textMuted)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testMode = ref.watch(testModeProvider);
    ref.watch(sessionProvider); // keeps the menu's profile entry current
    ref.listen<HomePairState>(homePairProvider, (prev, next) {
      final analytics = ref.read(homeAnalyticsProvider);
      if (next.phase == HomePairPhase.ready && next.pair != null && prev?.pair != next.pair) analytics.pairShown();
      if (next.phase == HomePairPhase.revealed && prev?.phase != HomePairPhase.revealed) {
        analytics.guess(correct: next.result!.correct);
      }
    });
    return GradientBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Size the pair so everything else still fits below it: about
            // 460 px of the height goes to the wordmark, question, result
            // line, button and mode row. Phones use the full width; tablets
            // cap the content at 660.
            final pairSide = (box.maxHeight - 460).clamp(120.0, 300.0);
            final width = [box.maxWidth, 660.0, pairSide * 2 + 48].reduce((a, b) => a < b ? a : b);
            return Center(
              child: SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 48),
                          const Expanded(child: Center(child: Logo(fontSize: 34))),
                          IconButton(
                            key: const ValueKey('home-menu'),
                            icon: const Icon(Icons.menu),
                            tooltip: 'Menu',
                            onPressed: _openMenu,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _handleSubtitleTap,
                        child: Text(
                          testMode ? 'Test Mode' : 'Spot the AI',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: testMode ? Colors.orange : AppTheme.textSecondary,
                              ),
                        ),
                      ),
                      const Spacer(),
                      if (!kIsWeb) ...[
                        Text(
                          'Which one is AI?',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        HomePairView(onNextPair: _startFromHome, nextPending: _nextPending),
                        const Spacer(),
                        Text('or pick a mode', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                      ],
                      const ModeRow(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
