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

  /// Get current user information with Odoo fields check
  /// POST /api/v1/auth/tenant/me
  /// Body: { "odoo_fields_check": { "model": "res.users", "list_fields": ["field1", "field2"] } }
  static const String meWithFieldsCheck = '/api/v1/auth/tenant/me';

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

  /// Create record by name only
  /// POST /api/v1/odoo/name_create
  static const String nameCreate = '/api/v1/odoo/name_create';

  // ════════════════════════════════════════════════════════════
  // Advanced Operations
  // ════════════════════════════════════════════════════════════

  /// Execute onchange - calculate field values automatically
  /// POST /api/v1/odoo/onchange
  static const String onchange = '/api/v1/odoo/onchange';

  /// Read grouped data (for reports and analytics)
  /// POST /api/v1/odoo/read_group
  static const String readGroup = '/api/v1/odoo/read_group';

  /// Get default values for fields
  /// POST /api/v1/odoo/default_get
  static const String defaultGet = '/api/v1/odoo/default_get';

  /// Copy/duplicate a record
  /// POST /api/v1/odoo/copy
  static const String copy = '/api/v1/odoo/copy';

  // ════════════════════════════════════════════════════════════
  // View Operations
  // ════════════════════════════════════════════════════════════

  /// Get view definition (Odoo ≤15)
  /// POST /api/v1/odoo/fields_view_get
  static const String fieldsViewGet = '/api/v1/odoo/fields_view_get';

  /// Get view definition (Odoo 16+)
  /// POST /api/v1/odoo/get_view
  static const String getView = '/api/v1/odoo/get_view';

  /// Load multiple views at once (Odoo ≤15)
  /// POST /api/v1/odoo/load_views
  static const String loadViews = '/api/v1/odoo/load_views';

  /// Load multiple views at once (Odoo 16+)
  /// POST /api/v1/odoo/get_views
  static const String getViews = '/api/v1/odoo/get_views';

  // ════════════════════════════════════════════════════════════
  // Permission Operations
  // ════════════════════════════════════════════════════════════

  /// Check access rights for an operation
  /// POST /api/v1/odoo/check_access_rights
  static const String checkAccessRights = '/api/v1/odoo/check_access_rights';

  // ════════════════════════════════════════════════════════════
  // Utility Operations
  // ════════════════════════════════════════════════════════════

  /// Check if records exist
  /// POST /api/v1/odoo/exists
  static const String exists = '/api/v1/odoo/exists';

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
  // Custom Method Operations
  // ════════════════════════════════════════════════════════════

  /// Call any Odoo method (generic caller)
  /// POST /api/v1/odoo/call_kw
  static const String callKw = '/api/v1/odoo/call_kw';

  /// Call custom method on model
  /// POST /api/v1/odoo/call_method
  static const String callMethod = '/api/v1/odoo/call_method';

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
  // Webhook Management (Compatible with BridgeCore Backend)
  // ════════════════════════════════════════════════════════════

  /// Get webhook events with filtering
  /// GET /api/v1/webhooks/events
  static const String webhookEvents = '/api/v1/webhooks/events';

  /// Check for updates (quick check)
  /// GET /api/v1/webhooks/check-updates
  static const String webhookCheckUpdates = '/api/v1/webhooks/check-updates';

  /// Get webhook configurations
  /// GET /api/v1/webhooks/configs
  static const String webhookConfigs = '/api/v1/webhooks/configs';

  /// Receive webhook push from Odoo
  /// POST /api/v1/webhooks/receive
  static const String webhookReceive = '/api/v1/webhooks/receive';

  /// Retry failed webhook
  /// POST /api/v1/webhooks/retry
  static const String webhookRetry = '/api/v1/webhooks/retry';

  /// Bulk retry failed webhooks
  /// POST /api/v1/webhooks/retry/bulk
  static const String webhookRetryBulk = '/api/v1/webhooks/retry/bulk';

  /// Cleanup old webhook events
  /// DELETE /api/v1/webhooks/cleanup
  static const String webhookCleanup = '/api/v1/webhooks/cleanup';

  /// Webhook service health check
  /// GET /api/v1/webhooks/health
  static const String webhookHealth = '/api/v1/webhooks/health';

  /// Get webhook statistics
  /// GET /api/v1/webhooks/statistics
  static const String webhookStatistics = '/api/v1/webhooks/statistics';

  /// Get enhanced webhook events
  /// GET /api/v1/webhooks/events/enhanced
  static const String webhookEventsEnhanced = '/api/v1/webhooks/events/enhanced';

  /// Get dead-letter queue statistics
  /// GET /api/v1/webhooks/dead-letter/stats
  static const String webhookDeadLetterStats = '/api/v1/webhooks/dead-letter/stats';

  // ════════════════════════════════════════════════════════════
  // Offline Sync (Compatible with BridgeCore Backend)
  // ════════════════════════════════════════════════════════════

  /// Push local changes to server
  /// POST /api/v1/offline-sync/push
  static const String offlineSyncPush = '/api/v1/offline-sync/push';

  /// Pull server changes
  /// POST /api/v1/offline-sync/pull
  static const String offlineSyncPull = '/api/v1/offline-sync/pull';

  /// Resolve sync conflicts
  /// POST /api/v1/offline-sync/resolve-conflicts
  static const String offlineSyncResolveConflicts = '/api/v1/offline-sync/resolve-conflicts';

  /// Get sync state
  /// GET /api/v1/offline-sync/state
  static const String offlineSyncState = '/api/v1/offline-sync/state';

  /// Reset sync state
  /// POST /api/v1/offline-sync/reset
  static const String offlineSyncReset = '/api/v1/offline-sync/reset';

  /// Offline sync health check
  /// GET /api/v1/offline-sync/health
  static const String offlineSyncHealth = '/api/v1/offline-sync/health';

  /// Get offline sync statistics
  /// GET /api/v1/offline-sync/statistics
  static const String offlineSyncStatistics = '/api/v1/offline-sync/statistics';

  // ════════════════════════════════════════════════════════════
  // Smart Sync V2 (Compatible with BridgeCore Backend)
  // ════════════════════════════════════════════════════════════

  /// Smart sync pull - pulls only new changes since last sync
  /// POST /api/v2/sync/pull
  static const String smartSyncV2Pull = '/api/v2/sync/pull';

  /// Get smart sync state for user/device
  /// GET /api/v2/sync/state
  static const String smartSyncV2State = '/api/v2/sync/state';

  /// Reset smart sync state
  /// POST /api/v2/sync/reset
  static const String smartSyncV2Reset = '/api/v2/sync/reset';

  /// Smart sync health check
  /// GET /api/v2/sync/health
  static const String smartSyncV2Health = '/api/v2/sync/health';

  // ════════════════════════════════════════════════════════════
  // Triggers Management
  // ════════════════════════════════════════════════════════════

  /// Create a new trigger
  /// POST /api/v1/triggers/create
  static const String triggerCreate = '/api/v1/triggers/create';

  /// List all triggers
  /// GET /api/v1/triggers/list
  static const String triggerList = '/api/v1/triggers/list';

  /// Get trigger details
  /// GET /api/v1/triggers/{id}
  static const String triggerGet = '/api/v1/triggers';

  /// Update trigger
  /// PUT /api/v1/triggers/{id}
  static const String triggerUpdate = '/api/v1/triggers';

  /// Delete trigger
  /// DELETE /api/v1/triggers/{id}
  static const String triggerDelete = '/api/v1/triggers';

  /// Enable/disable trigger
  /// POST /api/v1/triggers/{id}/toggle
  static const String triggerToggle = '/api/v1/triggers';

  /// Get trigger execution history
  /// GET /api/v1/triggers/{id}/history
  static const String triggerHistory = '/api/v1/triggers';

  /// Execute trigger manually
  /// POST /api/v1/triggers/{id}/execute
  static const String triggerExecute = '/api/v1/triggers';

  /// Get trigger statistics
  /// GET /api/v1/triggers/{id}/stats
  static const String triggerStats = '/api/v1/triggers';

  // ════════════════════════════════════════════════════════════
  // Notifications
  // ════════════════════════════════════════════════════════════

  /// Get user notifications
  /// GET /api/v1/notifications/list
  static const String notificationList = '/api/v1/notifications/list';

  /// Get notification by ID
  /// GET /api/v1/notifications/{id}
  static const String notificationGet = '/api/v1/notifications';

  /// Mark notification as read
  /// POST /api/v1/notifications/{id}/read
  static const String notificationMarkRead = '/api/v1/notifications';

  /// Mark multiple notifications as read
  /// POST /api/v1/notifications/mark-read
  static const String notificationMarkMultipleRead = '/api/v1/notifications/mark-read';

  /// Mark all notifications as read
  /// POST /api/v1/notifications/read-all
  static const String notificationReadAll = '/api/v1/notifications/read-all';

  /// Delete notification
  /// DELETE /api/v1/notifications/{id}
  static const String notificationDelete = '/api/v1/notifications';

  /// Get notification preferences
  /// GET /api/v1/notifications/preferences
  static const String notificationPreferences = '/api/v1/notifications/preferences';

  /// Update notification preferences
  /// PUT /api/v1/notifications/preferences
  static const String notificationUpdatePreferences = '/api/v1/notifications/preferences';

  /// Register device for push notifications
  /// POST /api/v1/notifications/register-device
  static const String notificationRegisterDevice = '/api/v1/notifications/register-device';

  /// Unregister device
  /// POST /api/v1/notifications/unregister-device
  static const String notificationUnregisterDevice = '/api/v1/notifications/unregister-device';

  /// List registered devices
  /// GET /api/v1/notifications/devices
  static const String notificationDevices = '/api/v1/notifications/devices';

  /// Get notification statistics
  /// GET /api/v1/notifications/stats
  static const String notificationStats = '/api/v1/notifications/stats';

  // ════════════════════════════════════════════════════════════
  // Odoo Sync (Direct integration with auto-webhook-odoo)
  // ════════════════════════════════════════════════════════════

  /// Pull events from Odoo's update.webhook
  /// POST /api/v1/odoo-sync/pull
  static const String odooSyncPull = '/api/v1/odoo-sync/pull';

  /// Pull events from Odoo (GET)
  /// GET /api/v1/odoo-sync/pull
  static const String odooSyncPullGet = '/api/v1/odoo-sync/pull';

  /// Acknowledge events as processed
  /// POST /api/v1/odoo-sync/ack
  static const String odooSyncAck = '/api/v1/odoo-sync/ack';

  /// Get or create sync state
  /// POST /api/v1/odoo-sync/sync-state
  static const String odooSyncState = '/api/v1/odoo-sync/sync-state';

  /// Update sync state
  /// POST /api/v1/odoo-sync/sync-state/update
  static const String odooSyncStateUpdate = '/api/v1/odoo-sync/sync-state/update';

  /// Get sync statistics
  /// GET /api/v1/odoo-sync/sync-state/stats
  static const String odooSyncStateStats = '/api/v1/odoo-sync/sync-state/stats';

  /// Smart pull with auto sync state
  /// POST /api/v1/odoo-sync/smart-pull
  static const String odooSyncSmartPull = '/api/v1/odoo-sync/smart-pull';

  /// Odoo sync health check
  /// GET /api/v1/odoo-sync/health
  static const String odooSyncHealth = '/api/v1/odoo-sync/health';

  /// Odoo sync statistics
  /// GET /api/v1/odoo-sync/stats
  static const String odooSyncStats = '/api/v1/odoo-sync/stats';

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
      // CRUD Operations
      create,
      read,
      write,
      unlink,
      // Search Operations
      search,
      searchRead,
      searchCount,
      // Name Operations
      nameSearch,
      nameGet,
      nameCreate,
      // Advanced Operations
      onchange,
      readGroup,
      defaultGet,
      copy,
      // View Operations
      fieldsGet,
      fieldsViewGet,
      getView,
      loadViews,
      getViews,
      // Permission Operations
      checkAccessRights,
      // Utility Operations
      exists,
      // Web Operations
      webSearchRead,
      webRead,
      webSave,
      // Batch Operations
      batchCreate,
      batchWrite,
      batchUnlink,
      batchExecute,
      // Custom Methods
      callKw,
      callMethod,
      // Cache
      cacheStats,
      cacheClear,
      // Webhooks
      webhookEvents,
      webhookCheckUpdates,
      webhookConfigs,
      webhookReceive,
      webhookRetry,
      webhookRetryBulk,
      webhookCleanup,
      webhookHealth,
      webhookStatistics,
      webhookEventsEnhanced,
      webhookDeadLetterStats,
      // Offline Sync
      offlineSyncPush,
      offlineSyncPull,
      offlineSyncResolveConflicts,
      offlineSyncState,
      offlineSyncReset,
      offlineSyncHealth,
      offlineSyncStatistics,
      // Smart Sync V2
      smartSyncV2Pull,
      smartSyncV2State,
      smartSyncV2Reset,
      smartSyncV2Health,
      // Triggers
      triggerCreate,
      triggerList,
      triggerGet,
      triggerUpdate,
      triggerDelete,
      triggerToggle,
      triggerHistory,
      triggerExecute,
      triggerStats,
      // Notifications
      notificationList,
      notificationGet,
      notificationMarkRead,
      notificationMarkMultipleRead,
      notificationReadAll,
      notificationDelete,
      notificationPreferences,
      notificationUpdatePreferences,
      notificationRegisterDevice,
      notificationUnregisterDevice,
      notificationDevices,
      notificationStats,
      // Odoo Sync
      odooSyncPull,
      odooSyncPullGet,
      odooSyncAck,
      odooSyncState,
      odooSyncStateUpdate,
      odooSyncStateStats,
      odooSyncSmartPull,
      odooSyncHealth,
      odooSyncStats,
    ];
  }
}
