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

/// 401 - Session Expired (refresh token also expired)
/// 
/// This is thrown when:
/// - The access token is expired AND
/// - The refresh token is also expired or invalid
/// - User must login again
/// 
/// Different from [UnauthorizedException] which might be recoverable
/// through token refresh.
class SessionExpiredException extends UnauthorizedException {
  SessionExpiredException(
    super.message, {
    super.statusCode = 401,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
  
  /// Create with default message
  factory SessionExpiredException.defaultMessage({
    String? endpoint,
    String? method,
  }) {
    return SessionExpiredException(
      'Your session has expired. Please login again.',
      endpoint: endpoint,
      method: method,
    );
  }
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

/// 402 - Payment Required (trial expired)
class PaymentRequiredException extends BridgeCoreException {
  PaymentRequiredException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}

/// 410 - Gone (account deleted)
class AccountDeletedException extends BridgeCoreException {
  AccountDeletedException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
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

/// 400 - Missing Odoo Credentials (token doesn't contain tenant info)
/// 
/// This exception is thrown when the JWT token doesn't contain the required
/// Odoo credentials. This typically happens when:
/// - Using a legacy token that doesn't have tenant info embedded
/// - The token was created before tenant-based auth was implemented
/// - The token is corrupted or incomplete
/// 
/// The recommended action is to logout and login again to get a fresh token.
class MissingOdooCredentialsException extends BridgeCoreException {
  MissingOdooCredentialsException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.endpoint,
    super.method,
    super.details,
  });
}