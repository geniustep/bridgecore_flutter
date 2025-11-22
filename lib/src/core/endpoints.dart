/// BridgeCore API Endpoints
/// 
/// All endpoints for BridgeCore API communication
class BridgeCoreEndpoints {
  BridgeCoreEndpoints._();

  // ════════════════════════════════════════════════════════════
  // Authentication Endpoints
  // ════════════════════════════════════════════════════════════

  /// Tenant user login
  /// POST /api/v1/auth/tenant/login
  static const String login = '/api/v1/auth/tenant/login';

  /// Refresh access token
  /// POST /api/v1/auth/tenant/refresh
  static const String refresh = '/api/v1/auth/tenant/refresh';

  /// Logout current user
  /// POST /api/v1/auth/tenant/logout
  static const String logout = '/api/v1/auth/tenant/logout';

  /// Get current user information
  /// GET /api/v1/auth/tenant/me
  static const String me = '/api/v1/auth/tenant/me';

  // ════════════════════════════════════════════════════════════
  // Odoo Operations Endpoints
  // ════════════════════════════════════════════════════════════

  /// Search and read records
  /// POST /api/v1/odoo/search_read
  static const String searchRead = '/api/v1/odoo/search_read';

  /// Read specific records by IDs
  /// POST /api/v1/odoo/read
  static const String read = '/api/v1/odoo/read';

  /// Create new record
  /// POST /api/v1/odoo/create
  static const String create = '/api/v1/odoo/create';

  /// Update existing records
  /// POST /api/v1/odoo/write
  static const String write = '/api/v1/odoo/write';

  /// Delete records
  /// POST /api/v1/odoo/unlink
  static const String unlink = '/api/v1/odoo/unlink';

  /// Search for record IDs
  /// POST /api/v1/odoo/search
  static const String search = '/api/v1/odoo/search';

  /// Count records matching domain
  /// POST /api/v1/odoo/search_count
  static const String searchCount = '/api/v1/odoo/search_count';

  /// Get model fields information
  /// POST /api/v1/odoo/fields_get
  static const String fieldsGet = '/api/v1/odoo/fields_get';

  /// Name search
  /// POST /api/v1/odoo/name_search
  static const String nameSearch = '/api/v1/odoo/name_search';

  /// Get display names for record IDs
  /// POST /api/v1/odoo/name_get
  static const String nameGet = '/api/v1/odoo/name_get';

  // ════════════════════════════════════════════════════════════
  // Web Operations (Odoo 14+)
  // ════════════════════════════════════════════════════════════

  /// Web search read (Odoo 14+)
  /// POST /api/v1/odoo/web_search_read
  static const String webSearchRead = '/api/v1/odoo/web_search_read';

  /// Web read (Odoo 14+)
  /// POST /api/v1/odoo/web_read
  static const String webRead = '/api/v1/odoo/web_read';

  /// Web save (Odoo 14+)
  /// POST /api/v1/odoo/web_save
  static const String webSave = '/api/v1/odoo/web_save';

  // ════════════════════════════════════════════════════════════
  // Batch Operations
  // ════════════════════════════════════════════════════════════

  /// Batch create records
  /// POST /api/v1/odoo/batch_create
  static const String batchCreate = '/api/v1/odoo/batch_create';

  /// Batch update records
  /// POST /api/v1/odoo/batch_write
  static const String batchWrite = '/api/v1/odoo/batch_write';

  /// Batch delete records
  /// POST /api/v1/odoo/batch_unlink
  static const String batchUnlink = '/api/v1/odoo/batch_unlink';

  /// Execute batch operations
  /// POST /api/v1/odoo/batch_execute
  static const String batchExecute = '/api/v1/odoo/batch_execute';

  // ════════════════════════════════════════════════════════════
  // Advanced Operations
  // ════════════════════════════════════════════════════════════

  /// Call any Odoo method
  /// POST /api/v1/odoo/call_kw
  static const String callKw = '/api/v1/odoo/call_kw';

  // ════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════

  /// Get cache statistics
  /// GET /api/v1/odoo/cache/stats
  static const String cacheStats = '/api/v1/odoo/cache/stats';

  /// Clear cache
  /// DELETE /api/v1/odoo/cache/clear
  static const String cacheClear = '/api/v1/odoo/cache/clear';

  // ════════════════════════════════════════════════════════════
  // Utility Methods
  // ════════════════════════════════════════════════════════════

  /// Get full URL for an endpoint
  static String getFullUrl(String baseUrl, String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Get list of all available endpoints
  static List<String> getAllEndpoints() {
    return [
      // Auth
      login,
      refresh,
      logout,
      me,
      // Odoo Operations
      searchRead,
      read,
      create,
      write,
      unlink,
      search,
      searchCount,
      fieldsGet,
      nameSearch,
      nameGet,
      // Web Operations
      webSearchRead,
      webRead,
      webSave,
      // Batch Operations
      batchCreate,
      batchWrite,
      batchUnlink,
      batchExecute,
      // Advanced
      callKw,
      // Cache
      cacheStats,
      cacheClear,
    ];
  }
}
