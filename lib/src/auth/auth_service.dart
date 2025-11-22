import '../client/http_client.dart';
import '../core/endpoints.dart';
import 'token_manager.dart';
import 'models/login_request.dart';
import 'models/tenant_session.dart';
import 'models/odoo_fields_check.dart';
import 'models/tenant_me_response.dart';

/// Authentication service
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
  Future<bool> get isLoggedIn => tokenManager.hasTokens();

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

    // Save tokens
    await tokenManager.saveTokens(
      session.accessToken,
      session.refreshToken,
    );

    return session;
  }

  /// Refresh access token using refresh token
  ///
  /// Returns new access token
  ///
  /// Throws [UnauthorizedException] if refresh token is invalid
  Future<String> refreshToken() async {
    final refreshToken = await tokenManager.getRefreshToken();

    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    // Set Authorization header manually for refresh
    final oldToken = await tokenManager.getAccessToken();
    await tokenManager.saveTokens(refreshToken, refreshToken);

    try {
      final response = await httpClient.post(
        BridgeCoreEndpoints.refresh,
        {},
      );

      final newAccessToken = response['access_token'] as String;

      // Save new access token (keep same refresh token)
      await tokenManager.saveTokens(newAccessToken, refreshToken);

      return newAccessToken;
    } catch (e) {
      // Restore old token if refresh failed
      if (oldToken != null) {
        await tokenManager.saveTokens(oldToken, refreshToken);
      }
      rethrow;
    }
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
    }
  }
}
