import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import 'api_exceptions.dart';

/// HTTP client for API communication using Dio.
///
/// Configured with retry logic, error handling, and logging.
class ApiClient {
  ApiClient._() {
    _dio = Dio(_baseOptions);
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(),
      _RetryInterceptor(_dio),
    ]);
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  static BaseOptions get _baseOptions => BaseOptions(
        baseUrl: Env.apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Mobile-App': Env.mobileAppSecret,
        },
      );

  /// Access the underlying Dio instance for custom requests.
  Dio get dio => _dio;

  /// GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Logging interceptor for debug builds.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('  Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ ${err.type} ${err.requestOptions.uri}');
      debugPrint('  ${err.message}');
    }
    handler.next(err);
  }
}

/// Error interceptor to convert Dio errors to custom exceptions.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }

  ApiException _mapException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Request timed out');

      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');

      case DioExceptionType.badResponse:
        return _mapResponseError(err.response);

      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled');

      default:
        return NetworkException(err.message ?? 'Network error');
    }
  }

  ApiException _mapResponseError(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    // Try to extract error message from response
    String message = 'Server error';
    String? errorCode;

    if (data is Map<String, dynamic>) {
      message = data['error'] as String? ??
          data['message'] as String? ??
          'Server error';
      errorCode = data['code'] as String?;
    }

    // Map specific status codes to exceptions
    switch (statusCode) {
      case 400:
        return ValidationException(message);

      case 404:
        if (message.toLowerCase().contains('game') ||
            message.toLowerCase().contains('not found')) {
          return GameNotFoundException(message);
        }
        return ServerException(message, statusCode: statusCode);

      case 409:
        // Conflict - could be various game-related errors
        if (message.toLowerCase().contains('full')) {
          return GameFullException(message);
        }
        if (message.toLowerCase().contains('started')) {
          return GameAlreadyStartedException(message);
        }
        if (message.toLowerCase().contains('name') ||
            message.toLowerCase().contains('taken')) {
          return NameTakenException(message);
        }
        return ServerException(message, statusCode: statusCode);

      case 500:
      case 502:
      case 503:
        return ServerException(message, statusCode: statusCode);

      default:
        return ServerException(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
    }
  }
}

/// Retry interceptor for transient failures.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on specific error types
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retries = err.requestOptions.extra['retries'] as int? ?? 0;
    if (retries >= _maxRetries) {
      handler.next(err);
      return;
    }

    // Wait before retrying with exponential backoff
    await Future.delayed(_retryDelay * (retries + 1));

    // Retry the request
    try {
      err.requestOptions.extra['retries'] = retries + 1;
      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection errors and server errors
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        // Retry on 502, 503, 504 (gateway/server errors)
        return statusCode == 502 || statusCode == 503 || statusCode == 504;

      default:
        return false;
    }
  }
}
