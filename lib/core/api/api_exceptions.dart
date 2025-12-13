/// Custom API exceptions for error handling.
library;

/// Base class for all API-related exceptions.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Network-related errors (no connection, timeout, etc).
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// Server returned an error response.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode, this.errorCode});

  final String? errorCode;
}

/// Game not found or invalid code.
class GameNotFoundException extends ApiException {
  const GameNotFoundException([super.message = 'Game not found'])
      : super(statusCode: 404);
}

/// Game is full (max 8 players).
class GameFullException extends ApiException {
  const GameFullException([super.message = 'Game is full'])
      : super(statusCode: 409);
}

/// Game already started (cannot join).
class GameAlreadyStartedException extends ApiException {
  const GameAlreadyStartedException([super.message = 'Game has already started'])
      : super(statusCode: 409);
}

/// Name already taken in the game.
class NameTakenException extends ApiException {
  const NameTakenException([super.message = 'Name is already taken'])
      : super(statusCode: 409);
}

/// Invalid request data.
class ValidationException extends ApiException {
  const ValidationException(super.message) : super(statusCode: 400);
}
