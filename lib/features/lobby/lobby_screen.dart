import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../widgets/gradient_background.dart';

/// Player model for the lobby.
class LobbyPlayer {
  const LobbyPlayer({
    required this.id,
    required this.name,
    required this.isHost,
  });

  final String id;
  final String name;
  final bool isHost;
}

/// Lobby screen showing players waiting for game to start.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.gameCode,
  });

  final String gameCode;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  // Mock data - will be replaced with WebSocket state in Epic 3.2
  late List<LobbyPlayer> _players;
  late bool _isHost;
  late String _playerName;

  // Game config (for host display)
  int _rounds = 6;
  int _timePerRound = 5;

  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    // Get data passed from create/join screen
    // In real implementation, this comes from WebSocket state
    _isHost = true; // Default for demo
    _playerName = 'Player';
    _players = [
      LobbyPlayer(id: '1', name: _playerName, isHost: _isHost),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract extra data from route if available
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _playerName = extra['playerName'] as String? ?? 'Player';
      _isHost = extra['isHost'] as bool? ?? false;

      final config = extra['config'] as Map<String, dynamic>?;
      if (config != null) {
        _rounds = config['rounds'] as int? ?? 6;
        _timePerRound = config['timePerRound'] as int? ?? 5;
      }

      // Update player list with actual name
      _players = [
        LobbyPlayer(id: '1', name: _playerName, isHost: _isHost),
        // Add mock players for demo
        if (!_isHost) const LobbyPlayer(id: '0', name: 'Host', isHost: true),
      ];
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

  Future<void> _startGame() async {
    if (!_isHost || _players.length < 2) return;

    setState(() => _isStarting = true);

    // TODO: Epic 3.2 - Send start message via WebSocket
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Navigate to game screen
    context.go('/game/${widget.gameCode}');
  }

  void _leaveGame() {
    // TODO: Epic 3.2 - Send leave message via WebSocket
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _isHost && _players.length >= 2;

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
                  // Settings/config display
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_rounds rounds  ·  ${_timePerRound}s',
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
                            '${_players.length}/8',
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
                      child: _PlayerList(players: _players),
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
                  if (_isHost) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
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

  final List<LobbyPlayer> players;

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

  final LobbyPlayer player;

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
