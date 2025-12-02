/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AppException: $message (statusCode: $statusCode)';
}

/// Server exception - thrown when API returns an error
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Network exception - thrown when there's no connection
class NetworkException extends AppException {
  const NetworkException()
      : super(message: 'No internet connection', statusCode: null);
}

/// Authentication exception - thrown for auth-related errors
class AuthenticationException extends AppException {
  const AuthenticationException({
    super.message = 'Authentication failed',
  }) : super(statusCode: 401);
}

/// Conflict exception - thrown when resource already exists
class ConflictException extends AppException {
  const ConflictException({
    super.message = 'Resource already exists',
  }) : super(statusCode: 409);
}

/// Cache exception - thrown when local storage fails
class CacheException extends AppException {
  const CacheException()
      : super(message: 'Failed to access local storage', statusCode: null);
}

