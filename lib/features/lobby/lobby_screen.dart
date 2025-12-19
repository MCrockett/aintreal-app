import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../core/websocket/game_state_provider.dart';
import '../../core/websocket/ws_client.dart';
import '../../core/websocket/ws_messages.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/how_to_play_dialog.dart';

/// Lobby screen showing players waiting for game to start.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({
    super.key,
    required this.gameCode,
  });

  final String gameCode;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isStarting = false;
  bool _initialized = false;
  bool _isSoloMode = false;
  bool _autoStartTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    // Check if already connected to this game (e.g., returning from Play Again)
    final currentState = ref.read(gameStateProvider);
    if (currentState.isConnected && currentState.code == widget.gameCode) {
      // Already connected to this game, no need to reconnect
      return;
    }

    // Extract extra data from route and connect WebSocket
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      final playerName = extra['playerName'] as String? ?? 'Player';
      final playerId = extra['playerId'] as String? ?? '';
      final isHost = extra['isHost'] as bool? ?? false;
      final configJson = extra['config'] as Map<String, dynamic>?;
      _isSoloMode = extra['isSoloMode'] as bool? ?? false;

      WsGameConfig? config;
      if (configJson != null) {
        config = WsGameConfig(
          rounds: configJson['rounds'] as int? ?? 6,
          timePerRound: configJson['timePerRound'] as int? ?? 5,
          speedBonus: configJson['speedBonus'] as bool? ?? true,
          randomBonuses: configJson['randomBonuses'] as bool? ?? true,
          mode: configJson['mode'] as String? ?? 'party',
        );
      }

      // Connect to WebSocket after the build cycle completes
      Future.microtask(() {
        if (!mounted) return;
        ref.read(gameStateProvider.notifier).connect(
              code: widget.gameCode,
              playerId: playerId,
              playerName: playerName,
              isHost: isHost,
              config: config,
            );
      });
    }
  }

  /// Auto-start game for solo modes once connected
  void _tryAutoStart() {
    if (!_isSoloMode || _autoStartTriggered) return;

    final gameState = ref.read(gameStateProvider);
    if (gameState.connectionState == WsConnectionState.connected &&
        gameState.isHost &&
        gameState.players.isNotEmpty) {
      _autoStartTriggered = true;
      debugPrint('Auto-starting solo game...');
      // Small delay to ensure connection is stable
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ref.read(gameStateProvider.notifier).startGame();
      });
    }
  }

  String get _joinUrl => '${Env.webBase}/join/${widget.gameCode}';

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.gameCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _joinUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQrCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan to Join',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _joinUrl,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.gameCode,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    final gameState = ref.read(gameStateProvider);
    debugPrint('_startGame called: isHost=${gameState.isHost}, playerId=${gameState.playerId}, hostId=${gameState.hostId}, players=${gameState.players.length}, isSoloMode=$_isSoloMode');

    // Solo modes only need 1 player, party mode needs 2+
    final minPlayers = _isSoloMode ? 1 : 2;
    if (!gameState.isHost || gameState.players.length < minPlayers) {
      debugPrint('_startGame blocked: isHost=${gameState.isHost}, playerCount=${gameState.players.length}, minPlayers=$minPlayers');
      return;
    }

    setState(() => _isStarting = true);
    ref.read(gameStateProvider.notifier).startGame();
  }

  void _leaveGame() {
    ref.read(gameStateProvider.notifier).leave();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    // Navigate to game screen when game starts
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (next.status == GameStatus.playing && next.roundData != null) {
        context.go('/game/${widget.gameCode}');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(gameStateProvider.notifier).clearError();
      }
    });

    // Auto-start for solo modes
    _tryAutoStart();

    final players = gameState.players;
    final isHost = gameState.isHost;
    final minPlayers = _isSoloMode ? 1 : 2;
    final canStart = isHost && players.length >= minPlayers;
    final config = gameState.config;

    // Solo mode: show simplified "Starting..." UI
    if (_isSoloMode) {
      return _SoloModeLoadingScreen(
        gameCode: widget.gameCode,
        config: config,
        connectionState: gameState.connectionState,
        onCancel: _leaveGame,
      );
    }

    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _leaveGame,
                  ),
                  const Spacer(),
                  // Connection status indicator
                  _ConnectionIndicator(state: gameState.connectionState),
                  const SizedBox(width: 12),
                  // Settings/config display
                  if (config != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${config.rounds} rounds  ·  ${config.timePerRound}s',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            ),

            // Game code display
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: _GameCodeCard(
                gameCode: widget.gameCode,
                onCopyCode: _copyCode,
                onCopyLink: _copyLink,
                onShowQr: _showQrCode,
              ),
            ),

            // Player list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Players',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${players.length}/8',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _PlayerList(players: players),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action area
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (isHost) ...[
                    // Start button (host only)
                    Container(
                      decoration: BoxDecoration(
                        gradient:
                            canStart ? AppTheme.primaryGradient : null,
                        color: canStart ? null : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: canStart && !_isStarting ? _startGame : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                        ),
                        child: _isStarting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                canStart
                                    ? 'Start Game'
                                    : 'Waiting for players...',
                                style: TextStyle(
                                  color: canStart
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                              ),
                      ),
                    ),
                    if (!canStart) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Need at least 2 players to start',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ] else ...[
                    // Waiting message (non-host)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondary, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Waiting for host to start...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // How to Play link
                  TextButton(
                    onPressed: () => showHowToPlayDialog(context),
                    child: const Text('How to Play'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection status indicator.
class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.state});

  final WsConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (state) {
      WsConnectionState.connected => (Colors.green, Icons.wifi),
      WsConnectionState.connecting => (Colors.orange, Icons.wifi),
      WsConnectionState.reconnecting => (Colors.orange, Icons.wifi_off),
      WsConnectionState.disconnected => (Colors.red, Icons.wifi_off),
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

/// Card displaying the game code with share options.
class _GameCodeCard extends StatelessWidget {
  const _GameCodeCard({
    required this.gameCode,
    required this.onCopyCode,
    required this.onCopyLink,
    required this.onShowQr,
  });

  final String gameCode;
  final VoidCallback onCopyCode;
  final VoidCallback onCopyLink;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Game Code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onCopyCode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  gameCode,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShareButton(
                icon: Icons.link,
                label: 'Copy Link',
                onTap: onCopyLink,
              ),
              const SizedBox(width: 12),
              _ShareButton(
                icon: Icons.qr_code,
                label: 'QR Code',
                onTap: onShowQr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small share button for code card.
class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of players in the lobby.
class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.players});

  final List<WsPlayer> players;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];
        return _PlayerTile(player: player);
      },
    );
  }
}

/// Single player tile in the list.
class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final WsPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: player.isHost
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (player.isHost)
                  Text(
                    'Host',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
          if (player.isHost)
            Icon(
              Icons.star,
              color: AppTheme.bonusRank,
              size: 20,
            ),
        ],
      ),
    );
  }
}

/// Loading screen for solo modes (Classic Solo, Marathon).
/// Shows a simple "Starting..." UI while connecting and auto-starting.
class _SoloModeLoadingScreen extends StatelessWidget {
  const _SoloModeLoadingScreen({
    required this.gameCode,
    required this.config,
    required this.connectionState,
    required this.onCancel,
  });

  final String gameCode;
  final WsGameConfig? config;
  final WsConnectionState connectionState;
  final VoidCallback onCancel;

  String get _modeTitle {
    final mode = config?.mode ?? 'classic';
    return switch (mode) {
      'marathon' => 'Marathon',
      'classic' => 'Classic Solo',
      _ => 'Solo Game',
    };
  }

  String get _statusText {
    return switch (connectionState) {
      WsConnectionState.connecting => 'Connecting...',
      WsConnectionState.connected => 'Starting game...',
      WsConnectionState.reconnecting => 'Reconnecting...',
      WsConnectionState.disconnected => 'Connection lost',
    };
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onCancel,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _modeTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  _ConnectionIndicator(state: connectionState),
                ],
              ),
            ),

            // Centered loading content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        config?.mode == 'marathon'
                            ? Icons.emoji_events
                            : Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Status text
                    Text(
                      _statusText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Config info
                    if (config != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${config!.rounds} rounds  ·  ${config!.timePerRound}s per round',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Cancel button at bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
