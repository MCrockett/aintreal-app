import 'dart:convert';
import 'dart:typed_data';

import 'package:aintreal_app/config/env.dart';
import 'package:aintreal_app/core/api/game_api.dart';
import 'package:aintreal_app/core/api/home_pair_api.dart';
import 'package:aintreal_app/models/game.dart';
import 'package:aintreal_app/models/home_pair.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each request with the next canned (status, body), or throws.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final List<Object> responses; // (int, Map) records or an Exception
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final next = responses.removeAt(0);
    if (next is Exception) throw next;
    final (status, body) = next as (int, Map<String, dynamic>);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(HomePairApi, _FakeAdapter) apiWith(List<Object> responses) {
  final adapter = _FakeAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
  return (HomePairApi(dio), adapter);
}

const _pairJson = {
  'leftUrl': '/api/images/p/aaa',
  'rightUrl': '/api/images/p/bbb',
  'pairToken': 'tok',
  'category': 'cats',
  'photographer': 'X',
  'photographerUrl': 'u',
};

void main() {
  test('fetch parses the pair and makes urls absolute', () async {
    final (api, adapter) = apiWith([(200, _pairJson)]);
    final pair = await api.fetch();
    expect(pair.leftUrl, '${Env.apiBase}/api/images/p/aaa');
    expect(pair.rightUrl, '${Env.apiBase}/api/images/p/bbb');
    expect(pair.pairToken, 'tok');
    expect(pair.category, 'cats');
    expect(adapter.requests.single.path, '/api/game/home-pair');
    expect(adapter.requests.single.queryParameters, isEmpty);
  });

  test('fetch with fullPool asks for pool=all', () async {
    final (api, adapter) = apiWith([(200, _pairJson)]);
    await api.fetch(fullPool: true);
    expect(adapter.requests.single.queryParameters, {'pool': 'all'});
  });

  test('guess parses the result and sends the choice', () async {
    final (api, adapter) = apiWith([
      (200, {'correct': true, 'aiSide': 'left', 'resultToken': 'res'}),
    ]);
    final r = await api.guess('tok', 'left');
    expect(r.correct, isTrue);
    expect(r.aiSide, 'left');
    expect(r.resultToken, 'res');
    expect(adapter.requests.single.path, '/api/game/home-guess');
    expect(adapter.requests.single.data, {'pairToken': 'tok', 'choice': 'left'});
  });

  test('expired and bad tokens give TokenExpired', () async {
    for (final code in ['expired_token', 'bad_token']) {
      final (api, _) = apiWith([(400, {'error': code})]);
      await expectLater(api.guess('tok', 'left'), throwsA(isA<TokenExpired>()));
    }
  });

  test('other failures give NetworkFailure', () async {
    final (api, _) = apiWith([const SocketExceptionLike()]);
    await expectLater(api.guess('tok', 'left'), throwsA(isA<NetworkFailure>()));
    final (api2, _) = apiWith([(500, {'error': 'boom'})]);
    await expectLater(api2.guess('tok', 'left'), throwsA(isA<NetworkFailure>()));
    final (api3, _) = apiWith([(404, {'error': 'no_pairs'})]);
    await expectLater(api3.fetch(), throwsA(isA<NetworkFailure>()));
  });

  test('createGame body carries firstRoundToken only when given', () {
    const config = GameConfig(mode: GameMode.classic);
    expect(GameApi.createBody(playerName: 'P', config: config, firstRoundToken: 'x')['firstRoundToken'], 'x');
    expect(GameApi.createBody(playerName: 'P', config: config).containsKey('firstRoundToken'), isFalse);
  });

  test('CreateGameResponse reads firstRound', () {
    final base = {
      'code': 'ABCD',
      'playerId': 'p',
      'gameState': {'code': 'ABCD', 'status': 'lobby', 'players': <dynamic>[], 'config': <String, dynamic>{}},
    };
    expect(CreateGameResponse.fromJson({...base, 'firstRound': 'applied'}).firstRound, 'applied');
    expect(CreateGameResponse.fromJson(base).firstRound, isNull);
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
