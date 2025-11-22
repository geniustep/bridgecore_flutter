/// Base exception for all BridgeCore errors
class BridgeCoreException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final String? endpoint;
  final String? method;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  BridgeCoreException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.endpoint,
    this.method,
    this.details,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (endpoint != null) {
      buffer.write(' [Endpoint: $method $endpoint]');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }

  /// Get error details as map
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'status_code': statusCode,
      'endpoint': endpoint,
      'method': method,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 401 - Unauthorized (invalid or expired token)
class UnauthorizedException extends BridgeCoreException {
  UnauthorizedException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}

/// 403 - Forbidden (no permission or tenant suspended)
class ForbiddenException extends BridgeCoreException {
  ForbiddenException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}

/// 403 - Tenant account is suspended
class TenantSuspendedException extends ForbiddenException {
  TenantSuspendedException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}

/// 404 - Resource not found
class NotFoundException extends BridgeCoreException {
  NotFoundException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}

/// 400 - Validation error
class ValidationException extends BridgeCoreException {
  ValidationException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}

/// Network connectivity error
class NetworkException extends BridgeCoreException {
  NetworkException(
    super.message, {
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  }) : super(statusCode: 0);
}

/// 500 - Server error
class ServerException extends BridgeCoreException {
  ServerException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}
