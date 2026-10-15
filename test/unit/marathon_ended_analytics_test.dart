import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/websocket/game_state_provider.dart';
import 'package:aintreal_app/core/websocket/ws_messages.dart';

void main() {
  group('marathon_ended analytics', () {
    late GameStateNotifier notifier;
    late List<(int, int)> logged;

    WsMessage marathonEnded(int streak) => WsMessage.fromJson({
          'type': 'marathon_ended',
          'streak': streak,
          'totalRounds': 26,
          'completed': streak == 26,
        });

    setUp(() {
      logged = [];
      notifier = GameStateNotifier(
        logMarathonEnded: ({required roundsCompleted, required score}) async {
          logged.add((roundsCompleted, score));
        },
      );
    });

    tearDown(() => notifier.dispose());

    test('logs rounds survived; 0 when round 1 is missed', () {
      notifier.handleMessage(marathonEnded(0));
      expect(logged, [(0, 0)]);
    });

    test('logs a perfect run as 26', () {
      notifier.handleMessage(marathonEnded(26));
      expect(logged, [(26, 2600)]);
    });

    test('logs once when the message is delivered twice', () {
      notifier.handleMessage(marathonEnded(7));
      notifier.handleMessage(marathonEnded(7));
      expect(logged, [(7, 700)]);
    });
  });
}
