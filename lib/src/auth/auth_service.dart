import '../client/http_client.dart';
import '../core/endpoints.dart';
import 'token_manager.dart';
import 'models/login_request.dart';
import 'models/tenant_session.dart';
import 'models/user_info.dart';
import 'models/odoo_fields_check.dart';

/// Authentication service
class AuthService {
  final BridgeCoreHttpClient httpClient;
  final TokenManager tokenManager;

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

  /// Get current user information
  ///
  /// Returns [UserInfo] with user and tenant details
  ///
  /// Throws [UnauthorizedException] if not logged in
  Future<UserInfo> me() async {
    final response = await httpClient.get(BridgeCoreEndpoints.me);
    return UserInfo.fromJson(response);
  }

  /// Logout current user
  ///
  /// Clears all stored tokens
  Future<void> logout() async {
    try {
      await httpClient.post(BridgeCoreEndpoints.logout, {});
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await tokenManager.clearTokens();
    }
  }
}
