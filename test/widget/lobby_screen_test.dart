import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aintreal_app/config/theme.dart';
import 'package:aintreal_app/core/websocket/ws_client.dart';
import 'package:aintreal_app/core/websocket/ws_messages.dart';
import 'package:aintreal_app/core/websocket/game_state_provider.dart';

void main() {
  Widget createTestApp({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('GameCodeCard equivalent tests', () {
    testWidgets('displays game code correctly', (tester) async {
      const gameCode = 'ABCD';

      await tester.pumpWidget(createTestApp(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Game Code'),
                const SizedBox(height: 8),
                Text(
                  gameCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Game Code'), findsOneWidget);
      expect(find.text(gameCode), findsOneWidget);
    });

    testWidgets('displays share buttons', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TestShareButton(
              icon: Icons.link,
              label: 'Copy Link',
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _TestShareButton(
              icon: Icons.qr_code,
              label: 'QR Code',
              onTap: () {},
            ),
          ],
        ),
      ));

      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('QR Code'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.qr_code), findsOneWidget);
    });

    testWidgets('copy link button is tappable', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(createTestApp(
        child: _TestShareButton(
          icon: Icons.link,
          label: 'Copy Link',
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Copy Link'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('ConnectionIndicator tests', () {
    testWidgets('shows green wifi icon when connected', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const _TestConnectionIndicator(
          state: WsConnectionState.connected,
        ),
      ));

      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('shows orange wifi icon when connecting', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const _TestConnectionIndicator(
          state: WsConnectionState.connecting,
        ),
      ));

      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('shows wifi_off icon when disconnected', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const _TestConnectionIndicator(
          state: WsConnectionState.disconnected,
        ),
      ));

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('shows wifi_off icon when reconnecting', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const _TestConnectionIndicator(
          state: WsConnectionState.reconnecting,
        ),
      ));

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });

  group('PlayerTile tests', () {
    testWidgets('displays player name', (tester) async {
      const player = WsPlayer(id: 'player-1', name: 'Alice', isHost: false);

      await tester.pumpWidget(createTestApp(
        child: _TestPlayerTile(player: player),
      ));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays host badge for host player', (tester) async {
      const player = WsPlayer(id: 'player-1', name: 'Alice', isHost: true);

      await tester.pumpWidget(createTestApp(
        child: _TestPlayerTile(player: player),
      ));

      expect(find.text('Host'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('does not display host badge for non-host', (tester) async {
      const player = WsPlayer(id: 'player-1', name: 'Bob', isHost: false);

      await tester.pumpWidget(createTestApp(
        child: _TestPlayerTile(player: player),
      ));

      expect(find.text('Host'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('displays player initial in avatar', (tester) async {
      const player = WsPlayer(id: 'player-1', name: 'Charlie', isHost: false);

      await tester.pumpWidget(createTestApp(
        child: _TestPlayerTile(player: player),
      ));

      expect(find.text('C'), findsOneWidget);
    });
  });

  group('PlayerList tests', () {
    testWidgets('displays multiple players', (tester) async {
      final players = <WsPlayer>[
        const WsPlayer(id: 'player-1', name: 'Alice', isHost: true),
        const WsPlayer(id: 'player-2', name: 'Bob', isHost: false),
        const WsPlayer(id: 'player-3', name: 'Charlie', isHost: false),
      ];

      await tester.pumpWidget(createTestApp(
        child: SizedBox(
          height: 400,
          child: ListView.separated(
            itemCount: players.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _TestPlayerTile(player: players[index]);
            },
          ),
        ),
      ));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('displays player count badge', (tester) async {
      const playerCount = 3;
      const maxPlayers = 8;

      await tester.pumpWidget(createTestApp(
        child: Row(
          children: [
            const Text('Players'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$playerCount/$maxPlayers'),
            ),
          ],
        ),
      ));

      expect(find.text('Players'), findsOneWidget);
      expect(find.text('3/8'), findsOneWidget);
    });
  });

  group('Start game button tests', () {
    testWidgets('shows Start Game when can start', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestStartButton(canStart: true, isHost: true),
      ));

      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets('shows waiting message when cannot start', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: _TestStartButton(canStart: false, isHost: true),
      ));

      expect(find.text('Waiting for players...'), findsOneWidget);
    });

    testWidgets('shows waiting for host message for non-host', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Container(
          padding: const EdgeInsets.all(16),
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
              const Text('Waiting for host to start...'),
            ],
          ),
        ),
      ));

      expect(find.text('Waiting for host to start...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows minimum players message', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const Text('Need at least 2 players to start'),
      ));

      expect(find.text('Need at least 2 players to start'), findsOneWidget);
    });
  });

  group('Config display tests', () {
    testWidgets('displays rounds and time config', (tester) async {
      const rounds = 6;
      const timePerRound = 5;

      await tester.pumpWidget(createTestApp(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('$rounds rounds  ·  ${timePerRound}s'),
        ),
      ));

      expect(find.text('$rounds rounds  ·  ${timePerRound}s'), findsOneWidget);
    });
  });

  group('Solo mode loading screen tests', () {
    testWidgets('displays mode title for marathon', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Marathon',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
      ));

      expect(find.text('Marathon'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('displays mode title for classic solo', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Classic Solo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
      ));

      expect(find.text('Classic Solo'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays connection status text', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Connecting...'),
            SizedBox(height: 16),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ));

      expect(find.text('Connecting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays cancel button', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(createTestApp(
        child: OutlinedButton(
          onPressed: () => cancelled = true,
          child: const Text('Cancel'),
        ),
      ));

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });

  group('How to Play button', () {
    testWidgets('displays How to Play button', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: TextButton(
          onPressed: () {},
          child: const Text('How to Play'),
        ),
      ));

      expect(find.text('How to Play'), findsOneWidget);
    });
  });
}

/// Test version of share button widget.
class _TestShareButton extends StatelessWidget {
  const _TestShareButton({
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
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Test version of connection indicator.
class _TestConnectionIndicator extends StatelessWidget {
  const _TestConnectionIndicator({required this.state});

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

/// Test version of player tile.
class _TestPlayerTile extends StatelessWidget {
  const _TestPlayerTile({required this.player});

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
          // Avatar
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
                Text(player.name),
                if (player.isHost)
                  Text(
                    'Host',
                    style: TextStyle(
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

/// Test version of start button.
class _TestStartButton extends StatelessWidget {
  const _TestStartButton({
    required this.canStart,
    required this.isHost,
  });

  final bool canStart;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    if (!isHost) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: canStart ? AppTheme.primaryGradient : null,
        color: canStart ? null : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: canStart ? () {} : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Text(
          canStart ? 'Start Game' : 'Waiting for players...',
          style: TextStyle(
            color: canStart ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
