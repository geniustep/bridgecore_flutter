import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages token storage and retrieval securely
class TokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _accessTokenKey = 'bridgecore_access_token';
  static const String _refreshTokenKey = 'bridgecore_refresh_token';

  /// Save access and refresh tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    debugPrint('[TokenManager] 💾 Saving tokens...');
    debugPrint('[TokenManager] Access token: ${accessToken.substring(0, 20)}...');
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
    debugPrint('[TokenManager] ✅ Tokens saved successfully');
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      debugPrint('[TokenManager] 🔑 Token found: ${token.substring(0, 20)}...');
    } else {
      debugPrint('[TokenManager] ⚠️ No token found in storage');
    }
    return token;
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Check if user is logged in (has tokens)
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
