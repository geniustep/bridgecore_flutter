import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/auth_tokens.dart';

/// Callback type for token refresh operation
typedef TokenRefreshCallback = Future<Map<String, dynamic>> Function(String refreshToken);

/// Token authentication state for offline-aware apps
enum TokenAuthState {
  /// User is authenticated with valid tokens
  authenticated,
  /// User has tokens but access is expired (can be refreshed)
  needsRefresh,
  /// All tokens expired - user must login
  sessionExpired,
  /// No tokens stored - user never logged in
  unauthenticated,
}

/// Manages token storage, retrieval, and smart refresh
/// 
/// Features:
/// - Secure token storage with expiry metadata
/// - Proactive token refresh before expiry
/// - Concurrency control (single refresh at a time)
/// - Offline-aware authentication state
class TokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _tokensKey = 'bridgecore_auth_tokens';
  
  // Legacy keys for migration
  static const String _legacyAccessTokenKey = 'bridgecore_access_token';
  static const String _legacyRefreshTokenKey = 'bridgecore_refresh_token';

  // Concurrency control
  bool _isRefreshing = false;
  Completer<AuthTokens?>? _refreshCompleter;

  // Refresh callback (set by BridgeCore)
  TokenRefreshCallback? _refreshCallback;

  // In-memory cache for performance
  AuthTokens? _cachedTokens;

  /// Set the refresh callback
  /// 
  /// This is called by BridgeCore during initialization
  void setRefreshCallback(TokenRefreshCallback callback) {
    _refreshCallback = callback;
  }

  /// Save tokens from login/refresh response
  /// 
  /// [accessToken] - The access token
  /// [refreshToken] - The refresh token
  /// [expiresIn] - Token validity in seconds
  /// [refreshExpiresIn] - Refresh token validity (optional, defaults to 30 days)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    int? refreshExpiresIn,
  }) async {
    debugPrint('[TokenManager] 💾 Saving tokens (expires in ${expiresIn}s)...');
    
    final tokens = AuthTokens.fromResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      refreshExpiresIn: refreshExpiresIn,
    );

    await _storage.write(key: _tokensKey, value: tokens.toJsonString());
    _cachedTokens = tokens;
    
    // Clean up legacy keys if they exist
    await _cleanupLegacyTokens();
    
    debugPrint('[TokenManager] ✅ Tokens saved (expires at ${tokens.accessExpiresAt})');
  }

  /// Read stored tokens
  Future<AuthTokens?> readTokens() async {
    // Return cached if available
    if (_cachedTokens != null) {
      return _cachedTokens;
    }

    final jsonString = await _storage.read(key: _tokensKey);
    
    // Try new format first
    if (jsonString != null) {
      _cachedTokens = AuthTokens.fromJsonString(jsonString);
      if (_cachedTokens != null) {
        return _cachedTokens;
      }
    }

    // Try migrating from legacy format
    final migrated = await _migrateLegacyTokens();
    if (migrated != null) {
      _cachedTokens = migrated;
      return migrated;
    }

    return null;
  }

  /// Get a valid access token, refreshing if necessary
  /// 
  /// This is the main method for getting tokens. It:
  /// 1. Returns cached token if still valid
  /// 2. Refreshes automatically if expired but refresh token is valid
  /// 3. Returns null if no valid session exists
  /// 
  /// Handles concurrency - multiple calls during refresh will wait for
  /// the single refresh operation to complete.
  Future<String?> getValidAccessToken() async {
    final tokens = await readTokens();
    
    if (tokens == null) {
      debugPrint('[TokenManager] ⚠️ No tokens found');
      return null;
    }

    // Token still valid - return it
    if (!tokens.isAccessExpired) {
      debugPrint('[TokenManager] 🔑 Token valid (expires in ${tokens.accessExpiresIn?.inMinutes}min)');
      return tokens.accessToken;
    }

    debugPrint('[TokenManager] ⏰ Access token expired, checking refresh...');

    // Refresh token also expired - session is dead
    if (tokens.isRefreshExpired) {
      debugPrint('[TokenManager] ❌ Refresh token also expired - session dead');
      await clearTokens();
      return null;
    }

    // Need to refresh - handle concurrency
    return await _refreshWithConcurrencyControl(tokens);
  }

  /// Refresh tokens with concurrency control
  Future<String?> _refreshWithConcurrencyControl(AuthTokens tokens) async {
    // If already refreshing, wait for that to complete
    if (_isRefreshing && _refreshCompleter != null) {
      debugPrint('[TokenManager] 🔄 Refresh already in progress, waiting...');
      final result = await _refreshCompleter!.future;
      return result?.accessToken;
    }

    // Start new refresh
    _isRefreshing = true;
    _refreshCompleter = Completer<AuthTokens?>();

    try {
      debugPrint('[TokenManager] 🔄 Starting token refresh...');
      final newTokens = await _doRefresh(tokens.refreshToken);
      
      _refreshCompleter!.complete(newTokens);
      _isRefreshing = false;
      _refreshCompleter = null;
      
      return newTokens?.accessToken;
    } catch (e) {
      debugPrint('[TokenManager] ❌ Refresh failed: $e');
      _refreshCompleter!.complete(null);
      _isRefreshing = false;
      _refreshCompleter = null;
      
      // Clear tokens on refresh failure
      await clearTokens();
      return null;
    }
  }

  /// Perform the actual token refresh
  Future<AuthTokens?> _doRefresh(String refreshToken) async {
    if (_refreshCallback == null) {
      throw Exception('TokenManager: No refresh callback set');
    }

    final response = await _refreshCallback!(refreshToken);
    
    final newAccessToken = response['access_token'] as String;
    final expiresIn = response['expires_in'] as int? ?? 3600;
    
    // Save new tokens
    await saveTokens(
      accessToken: newAccessToken,
      refreshToken: refreshToken, // Keep same refresh token
      expiresIn: expiresIn,
    );

    debugPrint('[TokenManager] ✅ Token refreshed successfully');
    return _cachedTokens;
  }

  /// Force refresh the token (for manual refresh scenarios)
  Future<String?> forceRefresh() async {
    final tokens = await readTokens();
    if (tokens == null) return null;
    
    if (tokens.isRefreshExpired) {
      await clearTokens();
      return null;
    }

    return await _refreshWithConcurrencyControl(tokens);
  }

  /// Get current authentication state
  Future<TokenAuthState> getAuthState() async {
    final tokens = await readTokens();
    
    if (tokens == null) {
      return TokenAuthState.unauthenticated;
    }

    if (!tokens.isAccessExpired) {
      return TokenAuthState.authenticated;
    }

    if (!tokens.isRefreshExpired) {
      return TokenAuthState.needsRefresh;
    }

    return TokenAuthState.sessionExpired;
  }

  /// Check if user is logged in (has any valid tokens)
  /// 
  /// For offline-first apps: returns true if we have tokens that can
  /// potentially be used (either valid access or valid refresh).
  /// This allows the app to work offline even if access token expired.
  Future<bool> hasTokens() async {
    final tokens = await readTokens();
    return tokens?.hasValidSession ?? false;
  }

  /// Check if user is logged in (strict mode)
  /// 
  /// Returns true only if access token is currently valid.
  /// Use this when you need to guarantee the token will work.
  Future<bool> hasValidAccessToken() async {
    final tokens = await readTokens();
    if (tokens == null) return false;
    return !tokens.isAccessExpired;
  }

  /// Get access token directly (without refresh)
  /// 
  /// Use getValidAccessToken() instead for most cases.
  /// This is kept for backwards compatibility.
  Future<String?> getAccessToken() async {
    final tokens = await readTokens();
    if (tokens != null) {
      debugPrint('[TokenManager] 🔑 Token found: ${tokens.accessToken.substring(0, 20)}...');
    } else {
      debugPrint('[TokenManager] ⚠️ No token found in storage');
    }
    return tokens?.accessToken;
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final tokens = await readTokens();
    return tokens?.refreshToken;
  }

  /// Get token expiry info (for debugging/UI)
  Future<Map<String, dynamic>> getTokenInfo() async {
    final tokens = await readTokens();
    if (tokens == null) {
      return {'hasTokens': false};
    }

    return {
      'hasTokens': true,
      'isAccessExpired': tokens.isAccessExpired,
      'isRefreshExpired': tokens.isRefreshExpired,
      'accessExpiresIn': tokens.accessExpiresIn?.inMinutes,
      'refreshExpiresIn': tokens.refreshExpiresIn?.inDays,
      'accessExpiresAt': tokens.accessExpiresAt?.toIso8601String(),
      'refreshExpiresAt': tokens.refreshExpiresAt?.toIso8601String(),
      'savedAt': tokens.savedAt.toIso8601String(),
    };
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    debugPrint('[TokenManager] 🗑️ Clearing all tokens');
    _cachedTokens = null;
    await Future.wait([
      _storage.delete(key: _tokensKey),
      _storage.delete(key: _legacyAccessTokenKey),
      _storage.delete(key: _legacyRefreshTokenKey),
    ]);
  }

  /// Migrate from legacy token storage format
  Future<AuthTokens?> _migrateLegacyTokens() async {
    final accessToken = await _storage.read(key: _legacyAccessTokenKey);
    final refreshToken = await _storage.read(key: _legacyRefreshTokenKey);

    if (accessToken != null && refreshToken != null) {
      debugPrint('[TokenManager] 📦 Migrating legacy tokens to new format');
      
      // Create tokens with default expiry (1 hour for access, 30 days for refresh)
      // Since we don't know the actual expiry, we'll be conservative
      final tokens = AuthTokens.fromResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: 3600, // Assume 1 hour
        refreshExpiresIn: 30 * 24 * 3600, // 30 days
      );

      // Save in new format
      await _storage.write(key: _tokensKey, value: tokens.toJsonString());
      
      // Clean up legacy
      await _cleanupLegacyTokens();
      
      return tokens;
    }

    return null;
  }

  /// Clean up legacy token storage
  Future<void> _cleanupLegacyTokens() async {
    await Future.wait([
      _storage.delete(key: _legacyAccessTokenKey),
      _storage.delete(key: _legacyRefreshTokenKey),
    ]);
  }

  // ════════════════════════════════════════════════════════════
  // Token Validation & Inspection
  // ════════════════════════════════════════════════════════════

  /// Decode JWT token payload without verification
  /// 
  /// This is useful for debugging and inspecting token contents.
  /// Note: This does NOT verify the token signature.
  Map<String, dynamic>? decodeTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('[TokenManager] ⚠️ Invalid JWT format (expected 3 parts, got ${parts.length})');
        return null;
      }

      // Decode the payload (second part)
      String payload = parts[1];
      
      // Add padding if needed for base64 decoding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[TokenManager] ❌ Failed to decode token: $e');
      return null;
    }
  }

  /// Check if the stored token is a valid tenant token
  /// 
  /// Returns a map with validation results:
  /// - `isValid`: true if token has required tenant fields
  /// - `userType`: the user_type claim from token
  /// - `tenantId`: the tenant_id claim from token
  /// - `sub`: the subject claim from token
  /// - `reason`: explanation if invalid
  Future<Map<String, dynamic>> validateTenantToken() async {
    final tokens = await readTokens();
    
    if (tokens == null) {
      return {
        'isValid': false,
        'reason': 'No token stored',
      };
    }

    final payload = decodeTokenPayload(tokens.accessToken);
    
    if (payload == null) {
      return {
        'isValid': false,
        'reason': 'Failed to decode token',
      };
    }

    final userType = payload['user_type'];
    final tenantId = payload['tenant_id'];
    final sub = payload['sub'];
    final type = payload['type'];

    debugPrint('[TokenManager] 🔍 Token inspection:');
    debugPrint('  - user_type: $userType');
    debugPrint('  - tenant_id: $tenantId');
    debugPrint('  - sub: $sub');
    debugPrint('  - type: $type');

    // Check if it's a valid tenant token
    final isValidTenantToken = userType == 'tenant' && tenantId != null;

    if (!isValidTenantToken) {
      String reason;
      if (userType != 'tenant') {
        reason = 'Token is not a tenant token (user_type: $userType)';
      } else if (tenantId == null) {
        reason = 'Token missing tenant_id';
      } else {
        reason = 'Unknown validation error';
      }

      debugPrint('[TokenManager] ⚠️ Invalid tenant token: $reason');
      
      return {
        'isValid': false,
        'userType': userType,
        'tenantId': tenantId,
        'sub': sub,
        'reason': reason,
        'payload': payload,
      };
    }

    debugPrint('[TokenManager] ✅ Valid tenant token');
    
    return {
      'isValid': true,
      'userType': userType,
      'tenantId': tenantId,
      'sub': sub,
      'payload': payload,
    };
  }

  /// Check if current token is a valid tenant token
  /// 
  /// Returns true only if the token has:
  /// - user_type: "tenant"
  /// - tenant_id: not null
  Future<bool> isTenantToken() async {
    final validation = await validateTenantToken();
    return validation['isValid'] == true;
  }

  /// Get detailed token info for debugging
  /// 
  /// Returns comprehensive information about the stored token
  /// including decoded payload for inspection.
  Future<Map<String, dynamic>> getDetailedTokenInfo() async {
    final basicInfo = await getTokenInfo();
    
    if (basicInfo['hasTokens'] != true) {
      return basicInfo;
    }

    final tokens = await readTokens();
    if (tokens == null) {
      return basicInfo;
    }

    final payload = decodeTokenPayload(tokens.accessToken);
    final validation = await validateTenantToken();

    return {
      ...basicInfo,
      'isTenantToken': validation['isValid'],
      'userType': validation['userType'],
      'tenantId': validation['tenantId'],
      'sub': validation['sub'],
      'validationReason': validation['reason'],
      'tokenPreview': tokens.accessToken.length > 50 
          ? '${tokens.accessToken.substring(0, 50)}...'
          : tokens.accessToken,
      'payload': payload,
    };
  }
}
