import 'client/http_client.dart';
import 'auth/auth_service.dart';
import 'auth/token_manager.dart';
import 'odoo/odoo_service.dart';
import 'core/logger.dart';
import 'triggers/trigger_service.dart';
import 'notifications/notification_service.dart';
import 'sync/sync_service.dart';

/// Main BridgeCore SDK class
/// 
/// Initialize once in your app:
/// ```dart
/// void main() {
///   BridgeCore.initialize(baseUrl: 'https://api.yourdomain.com');
///   runApp(MyApp());
/// }
/// ```
class BridgeCore {
  static BridgeCore? _instance;
  
  /// Get the singleton instance
  static BridgeCore get instance {
    if (_instance == null) {
      throw Exception(
        'BridgeCore not initialized. Call BridgeCore.initialize() first.'
      );
    }
    return _instance!;
  }

  late final BridgeCoreHttpClient _httpClient;
  late final TokenManager _tokenManager;
  late final AuthService _authService;
  late final OdooService _odooService;
  late final TriggerService _triggerService;
  late final NotificationService _notificationService;
  late final SyncService _syncService;

  /// Authentication service
  AuthService get auth => _authService;
  
  /// Odoo operations service
  OdooService get odoo => _odooService;

  /// Trigger automation service
  TriggerService get triggers => _triggerService;

  /// Notification service
  NotificationService get notifications => _notificationService;

  /// Sync service (offline sync & smart sync)
  SyncService get sync => _syncService;

  BridgeCore._internal({
    required String baseUrl,
    bool debugMode = false,
    Duration timeout = const Duration(seconds: 30),
    bool enableRetry = true,
    int maxRetries = 3,
    bool enableCache = false,
    bool enableLogging = false,
    LogLevel logLevel = LogLevel.info,
  }) {
    // Setup logging
    BridgeCoreLogger.setEnabled(enableLogging || debugMode);
    BridgeCoreLogger.setLevel(logLevel);

    _tokenManager = TokenManager();
    _httpClient = BridgeCoreHttpClient(
      baseUrl: baseUrl,
      tokenManager: _tokenManager,
      debugMode: debugMode,
      timeout: timeout,
      enableRetry: enableRetry,
      maxRetries: maxRetries,
      enableCache: enableCache,
    );
    _authService = AuthService(
      httpClient: _httpClient,
      tokenManager: _tokenManager,
    );
    _odooService = OdooService(httpClient: _httpClient);
    _triggerService = TriggerService(httpClient: _httpClient);
    _notificationService = NotificationService(httpClient: _httpClient);
    _syncService = SyncService(httpClient: _httpClient);
  }

  /// Initialize BridgeCore SDK
  /// 
  /// Must be called before using the SDK
  /// 
  /// Example:
  /// ```dart
  /// BridgeCore.initialize(
  ///   baseUrl: 'https://api.yourdomain.com',
  ///   debugMode: true,
  /// );
  /// ```
  static void initialize({
    required String baseUrl,
    bool debugMode = false,
    Duration timeout = const Duration(seconds: 30),
    bool enableRetry = true,
    int maxRetries = 3,
    bool enableCache = false,
    bool enableLogging = false,
    LogLevel logLevel = LogLevel.info,
  }) {
    _instance = BridgeCore._internal(
      baseUrl: baseUrl,
      debugMode: debugMode,
      timeout: timeout,
      enableRetry: enableRetry,
      maxRetries: maxRetries,
      enableCache: enableCache,
      enableLogging: enableLogging,
      logLevel: logLevel,
    );
  }

  /// Set a custom header for all requests
  void setCustomHeader(String key, String value) {
    _httpClient.setCustomHeader(key, value);
  }

  /// Set request timeout
  void setTimeout(Duration timeout) {
    _httpClient.setTimeout(timeout);
  }

  /// Enable or disable debug mode
  void setDebugMode(bool enabled) {
    _httpClient.setDebugMode(enabled);
    BridgeCoreLogger.setEnabled(enabled);
  }

  /// Enable or disable cache
  void setCacheEnabled(bool enabled) {
    _httpClient.setCacheEnabled(enabled);
  }

  /// Clear cache
  void clearCache() {
    _httpClient.clearCache();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _httpClient.getCacheStats();
  }

  /// Get metrics summary
  Map<String, dynamic> getMetrics() {
    return _httpClient.getMetrics();
  }

  /// Get endpoint statistics
  Map<String, Map<String, dynamic>> getEndpointStats() {
    return _httpClient.getEndpointStats();
  }

  /// Enable or disable logging
  void setLoggingEnabled(bool enabled) {
    BridgeCoreLogger.setEnabled(enabled);
  }

  /// Set log level
  void setLogLevel(LogLevel level) {
    BridgeCoreLogger.setLevel(level);
  }
}
