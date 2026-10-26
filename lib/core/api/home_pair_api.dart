import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../models/home_pair.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'endpoints.dart';

/// Guess on open: home pair and server-checked guess.
class HomePairApi {
  HomePairApi(this._dio);

  static final HomePairApi instance = HomePairApi(ApiClient.instance.dio);

  final Dio _dio;

  /// One random pair: the demo pool, or every pair with [fullPool].
  Future<HomePair> fetch({bool fullPool = false}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        Endpoints.homePair,
        queryParameters: fullPool ? {'pool': 'all'} : null,
      );
      final d = res.data!;
      return HomePair(
        leftUrl: '${Env.apiBase}${d['leftUrl']}',
        rightUrl: '${Env.apiBase}${d['rightUrl']}',
        pairToken: d['pairToken'] as String,
        category: d['category'] as String?,
        photographer: d['photographer'] as String?,
      );
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  /// Sends the guess ([choice] is 'left' or 'right').
  /// Throws [TokenExpired] or [NetworkFailure].
  Future<GuessResult> guess(String pairToken, String choice) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        Endpoints.homeGuess,
        data: {'pairToken': pairToken, 'choice': choice},
      );
      final d = res.data!;
      return GuessResult(
        correct: d['correct'] as bool,
        aiSide: d['aiSide'] as String,
        resultToken: d['resultToken'] as String,
      );
    } on DioException catch (e) {
      if (_isTokenError(e)) throw const TokenExpired();
      throw const NetworkFailure();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  static bool _isTokenError(DioException e) {
    const codes = {'expired_token', 'bad_token'};
    final error = e.error;
    if (error is ApiException && codes.contains(error.message)) return true;
    final data = e.response?.data;
    return data is Map && codes.contains(data['error']);
  }
}

final homePairApiProvider = Provider<HomePairApi>((ref) => HomePairApi.instance);
