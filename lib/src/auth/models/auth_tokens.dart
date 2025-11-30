import 'dart:convert';

/// Represents authentication tokens with expiry metadata
/// 
/// This model stores both access and refresh tokens along with their
/// expiration times, enabling smart token management for offline-first apps.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessExpiresAt;
  final DateTime? refreshExpiresAt;
  final DateTime savedAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessExpiresAt,
    this.refreshExpiresAt,
    required this.savedAt,
  });

  /// Creates AuthTokens from login/refresh response
  /// 
  /// [accessToken] - The access token string
  /// [refreshToken] - The refresh token string
  /// [expiresIn] - Token validity in seconds (from API response)
  /// [refreshExpiresIn] - Refresh token validity in seconds (optional)
  factory AuthTokens.fromResponse({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    int? refreshExpiresIn,
  }) {
    final now = DateTime.now();
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessExpiresAt: now.add(Duration(seconds: expiresIn)),
      // Default refresh token validity: 30 days if not specified
      refreshExpiresAt: refreshExpiresIn != null
          ? now.add(Duration(seconds: refreshExpiresIn))
          : now.add(const Duration(days: 30)),
      savedAt: now,
    );
  }

  /// Creates AuthTokens from stored JSON
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: json['access_expires_at'] != null
          ? DateTime.parse(json['access_expires_at'] as String)
          : null,
      refreshExpiresAt: json['refresh_expires_at'] != null
          ? DateTime.parse(json['refresh_expires_at'] as String)
          : null,
      savedAt: json['saved_at'] != null
          ? DateTime.parse(json['saved_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts to JSON for secure storage
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_expires_at': accessExpiresAt?.toIso8601String(),
      'refresh_expires_at': refreshExpiresAt?.toIso8601String(),
      'saved_at': savedAt.toIso8601String(),
    };
  }

  /// Converts to JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Creates from JSON string
  static AuthTokens? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Check if access token is expired
  /// 
  /// Adds a 30-second buffer to ensure token is refreshed before actual expiry
  bool get isAccessExpired {
    if (accessExpiresAt == null) return false;
    // Add 30 second buffer for network latency
    return DateTime.now().isAfter(
      accessExpiresAt!.subtract(const Duration(seconds: 30)),
    );
  }

  /// Check if refresh token is expired
  bool get isRefreshExpired {
    if (refreshExpiresAt == null) return false;
    return DateTime.now().isAfter(refreshExpiresAt!);
  }

  /// Check if we have valid tokens (either access is valid or can be refreshed)
  bool get hasValidSession {
    // If access token is still valid
    if (!isAccessExpired) return true;
    // Or if we can refresh it
    if (!isRefreshExpired) return true;
    return false;
  }

  /// Time until access token expires
  Duration? get accessExpiresIn {
    if (accessExpiresAt == null) return null;
    final diff = accessExpiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Time until refresh token expires
  Duration? get refreshExpiresIn {
    if (refreshExpiresAt == null) return null;
    final diff = refreshExpiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Creates a copy with new access token (after refresh)
  AuthTokens copyWithNewAccessToken({
    required String newAccessToken,
    required int expiresIn,
  }) {
    return AuthTokens(
      accessToken: newAccessToken,
      refreshToken: refreshToken,
      accessExpiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      refreshExpiresAt: refreshExpiresAt,
      savedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AuthTokens('
        'accessExpired: $isAccessExpired, '
        'refreshExpired: $isRefreshExpired, '
        'accessExpiresIn: ${accessExpiresIn?.inMinutes}min, '
        'refreshExpiresIn: ${refreshExpiresIn?.inDays}days)';
  }
}

