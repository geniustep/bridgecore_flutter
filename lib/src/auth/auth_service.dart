import 'package:flutter/foundation.dart';

import '../client/http_client.dart';
import '../core/endpoints.dart';
import 'token_manager.dart';
import 'models/login_request.dart';
import 'models/tenant_session.dart';
import 'models/odoo_fields_check.dart';
import 'models/tenant_me_response.dart';

/// Authentication service
/// 
/// Handles user authentication, token management, and session state.
/// Works with [TokenManager] for smart token handling including:
/// - Proactive token refresh before expiry
/// - Offline-aware session state
/// - Concurrency-safe refresh operations
class AuthService {
  final BridgeCoreHttpClient httpClient;
  final TokenManager tokenManager;

  // Cache for /me response
  TenantMeResponse? _cachedMeResponse;
  DateTime? _meResponseCachedAt;
  static const Duration _meCacheDuration = Duration(minutes: 5);

  AuthService({
    required this.httpClient,
    required this.tokenManager,
  });

  /// Check if user is logged in
  /// 
  /// For offline-first apps: returns true if we have tokens that can
  /// potentially be used (either valid access or valid refresh token).
  /// This allows the app to work offline even if access token expired.
  Future<bool> get isLoggedIn => tokenManager.hasTokens();

  /// Check if user has a valid access token right now
  /// 
  /// Use this when you need to guarantee the token will work immediately.
  Future<bool> get hasValidSession => tokenManager.hasValidAccessToken();

  /// Get current authentication state
  /// 
  /// Returns detailed state for UI decisions:
  /// - [TokenAuthState.authenticated]: Valid access token
  /// - [TokenAuthState.needsRefresh]: Access expired but can refresh
  /// - [TokenAuthState.sessionExpired]: All tokens expired
  /// - [TokenAuthState.unauthenticated]: No tokens stored
  Future<TokenAuthState> get authState => tokenManager.getAuthState();

  /// Login with email and password
  ///
  /// Returns [TenantSession] with tokens and user/tenant info
  ///
  /// Optionally check Odoo custom fields during login:
  /// ```dart
  /// final session = await auth.login(
  ///   email: 'user@company.com',
  ///   password: 'password',
  ///   odooFieldsCheck: OdooFieldsCheck(
  ///     model: 'res.users',
  ///     listFields: ['x_employee_code', 'x_department'],
  ///   ),
  /// );
  /// ```
  ///
  /// Throws [UnauthorizedException] if credentials are invalid
  /// Throws [TenantSuspendedException] if tenant is suspended
  /// Throws [PaymentRequiredException] if trial period expired
  /// Throws [AccountDeletedException] if account is deleted
  Future<TenantSession> login({
    required String email,
    required String password,
    OdooFieldsCheck? odooFieldsCheck,
  }) async {
    // If the app is switching accounts without an explicit logout,
    // ensure we don't reuse any cached user-scoped state.
    clearMeCache();
    httpClient.clearCache();

    final request = LoginRequest(
      email: email,
      password: password,
      odooFieldsCheck: odooFieldsCheck,
    );

    final response = await httpClient.post(
      BridgeCoreEndpoints.login,
      request.toJson(),
      includeAuth: false,
    );

    final session = TenantSession.fromJson(response);

    // Save tokens with expiry metadata
    await tokenManager.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresIn: session.expiresIn,
    );

    // New identity => drop any stale caches
    clearMeCache();
    httpClient.clearCache();

    return session;
  }

  /// Refresh access token
  ///
  /// Returns new access token. This is handled automatically by
  /// [TokenManager.getValidAccessToken()], but can be called manually
  /// if needed.
  ///
  /// Throws [UnauthorizedException] if refresh token is invalid
  Future<String> refreshToken() async {
    final newToken = await tokenManager.forceRefresh();
    
    if (newToken == null) {
      throw Exception('Failed to refresh token - please login again');
    }
    
    return newToken;
  }

  /// Get token information for debugging/UI
  /// 
  /// Returns details about current token state:
  /// - hasTokens: Whether any tokens exist
  /// - isAccessExpired: Whether access token is expired
  /// - isRefreshExpired: Whether refresh token is expired
  /// - accessExpiresIn: Minutes until access expires
  /// - refreshExpiresIn: Days until refresh expires
  Future<Map<String, dynamic>> getTokenInfo() async {
    return tokenManager.getTokenInfo();
  }

  /// Get current user information with enhanced Odoo data
  ///
  /// Returns comprehensive user info including:
  /// - User profile from BridgeCore
  /// - Tenant information
  /// - Odoo partner_id and employee_id
  /// - Odoo groups and permissions
  /// - Company information
  /// - Optional custom Odoo fields
  ///
  /// Example:
  /// ```dart
  /// // Basic usage (no custom fields)
  /// final userInfo = await BridgeCore.instance.auth.me();
  /// print('Partner ID: ${userInfo.partnerId}');
  /// print('Is Admin: ${userInfo.isAdmin}');
  ///
  /// // With custom fields
  /// final userInfoWithFields = await BridgeCore.instance.auth.me(
  ///   odooFieldsCheck: OdooFieldsCheck(
  ///     model: 'res.users',
  ///     listFields: ['shuttle_role', 'phone', 'mobile'],
  ///   ),
  /// );
  /// print('Custom Fields: ${userInfoWithFields.odooFieldsData}');
  ///
  /// // Force refresh (bypass cache)
  /// final freshInfo = await BridgeCore.instance.auth.me(forceRefresh: true);
  /// ```
  Future<TenantMeResponse> me({
    OdooFieldsCheck? odooFieldsCheck,
    bool forceRefresh = false,
  }) async {
    // Return cached response if valid and no custom fields requested
    if (!forceRefresh &&
        odooFieldsCheck == null &&
        _cachedMeResponse != null &&
        _meResponseCachedAt != null &&
        DateTime.now().difference(_meResponseCachedAt!) < _meCacheDuration) {
      return _cachedMeResponse!;
    }

    // Build request body
    final Map<String, dynamic> body = {};
    if (odooFieldsCheck != null) {
      body['odoo_fields_check'] = odooFieldsCheck.toJson();
    }

    final response = await httpClient.post(
      BridgeCoreEndpoints.me,
      body,
    );

    final meResponse = TenantMeResponse.fromJson(response);

    // Cache only if no custom fields were requested
    if (odooFieldsCheck == null) {
      _cachedMeResponse = meResponse;
      _meResponseCachedAt = DateTime.now();
    }

    return meResponse;
  }

  /// Clear cached /me response
  void clearMeCache() {
    _cachedMeResponse = null;
    _meResponseCachedAt = null;
  }

  /// Logout current user
  ///
  /// Clears all stored tokens and caches
  Future<void> logout() async {
    try {
      await httpClient.post(BridgeCoreEndpoints.logout, {});
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await tokenManager.clearTokens();
      clearMeCache();
      httpClient.clearCache();
    }
  }

  // ════════════════════════════════════════════════════════════
  // Token Validation
  // ════════════════════════════════════════════════════════════

  /// Validate that the stored token is a proper tenant token
  /// 
  /// This checks if the JWT token contains the required claims:
  /// - user_type: "tenant"
  /// - tenant_id: not null
  /// 
  /// If the token is invalid, it means the user needs to re-login
  /// to get a proper tenant token.
  /// 
  /// Returns a map with:
  /// - `isValid`: true if token is a valid tenant token
  /// - `reason`: explanation if invalid
  /// - `userType`, `tenantId`, `sub`: token claims
  Future<Map<String, dynamic>> validateToken() async {
    return tokenManager.validateTenantToken();
  }

  /// Check if the current token is a valid tenant token
  /// 
  /// Returns true only if the token has proper tenant claims.
  /// Use this to determine if the user needs to re-login.
  Future<bool> hasValidTenantToken() async {
    return tokenManager.isTenantToken();
  }

  /// Get detailed token information for debugging
  /// 
  /// Useful for diagnosing authentication issues.
  Future<Map<String, dynamic>> getDetailedTokenInfo() async {
    return tokenManager.getDetailedTokenInfo();
  }

  /// Validate token and logout if invalid
  /// 
  /// This is a convenience method that:
  /// 1. Validates the token is a proper tenant token
  /// 2. If invalid, automatically logs out the user
  /// 3. Returns whether the token was valid
  /// 
  /// Use this at app startup to ensure clean state.
  Future<bool> validateAndCleanup() async {
    final validation = await validateToken();
    
    if (validation['isValid'] != true) {
      debugPrint('[AuthService] ⚠️ Invalid token detected: ${validation['reason']}');
      debugPrint('[AuthService] 🔄 Clearing invalid tokens...');
      await logout();
      return false;
    }
    
    return true;
  }
}
