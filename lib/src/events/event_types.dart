/// BridgeCore Event Types
///
/// Defines all standard event types in the system
class BridgeCoreEventTypes {
  BridgeCoreEventTypes._();

  // ════════════════════════════════════════════════════════════
  // Authentication Events
  // ════════════════════════════════════════════════════════════

  /// User logged in successfully
  static const String authLogin = 'auth.login';

  /// User logged out
  static const String authLogout = 'auth.logout';

  /// Access token refreshed
  static const String authTokenRefreshed = 'auth.token_refreshed';

  /// Token refresh failed
  static const String authTokenRefreshFailed = 'auth.token_refresh_failed';

  /// User session expired
  static const String authSessionExpired = 'auth.session_expired';

  /// Login failed
  static const String authLoginFailed = 'auth.login_failed';

  // ════════════════════════════════════════════════════════════
  // Odoo Record Events
  // ════════════════════════════════════════════════════════════

  /// Record created in Odoo
  static const String odooRecordCreated = 'odoo.record_created';

  /// Record updated in Odoo
  static const String odooRecordUpdated = 'odoo.record_updated';

  /// Record deleted in Odoo
  static const String odooRecordDeleted = 'odoo.record_deleted';

  /// Batch operation completed
  static const String odooBatchCompleted = 'odoo.batch_completed';

  /// Batch operation failed
  static const String odooBatchFailed = 'odoo.batch_failed';

  // ════════════════════════════════════════════════════════════
  // Webhook Events
  // ════════════════════════════════════════════════════════════

  /// Webhook received from server
  static const String webhookReceived = 'webhook.received';

  /// Webhook registered successfully
  static const String webhookRegistered = 'webhook.registered';

  /// Webhook unregistered
  static const String webhookUnregistered = 'webhook.unregistered';

  /// Webhook delivery failed
  static const String webhookDeliveryFailed = 'webhook.delivery_failed';

  // ════════════════════════════════════════════════════════════
  // Sync Events
  // ════════════════════════════════════════════════════════════

  /// Updates available
  static const String updatesAvailable = 'updates.available';

  /// Sync started
  static const String syncStarted = 'sync.started';

  /// Sync completed successfully
  static const String syncCompleted = 'sync.completed';

  /// Sync failed
  static const String syncFailed = 'sync.failed';

  /// Sync progress update
  static const String syncProgress = 'sync.progress';

  /// Sync cancelled
  static const String syncCancelled = 'sync.cancelled';

  /// Sync push completed
  static const String syncPushCompleted = 'sync.push_completed';

  /// Sync conflict detected
  static const String syncConflictDetected = 'sync.conflict_detected';

  /// Sync conflict resolved
  static const String syncConflictResolved = 'sync.conflict_resolved';

  /// Sync state reset
  static const String syncStateReset = 'sync.state_reset';

  /// Smart sync completed (V2)
  static const String smartSyncCompleted = 'sync.smart_completed';

  // ════════════════════════════════════════════════════════════
  // Trigger Events
  // ════════════════════════════════════════════════════════════

  /// Trigger executed successfully
  static const String triggerExecuted = 'trigger.executed';

  /// Trigger execution failed
  static const String triggerFailed = 'trigger.failed';

  /// Trigger created
  static const String triggerCreated = 'trigger.created';

  /// Trigger deleted
  static const String triggerDeleted = 'trigger.deleted';

  /// Trigger updated
  static const String triggerUpdated = 'trigger.updated';

  // ════════════════════════════════════════════════════════════
  // Notification Events
  // ════════════════════════════════════════════════════════════

  /// Notification received
  static const String notificationReceived = 'notification.received';

  /// Notification sent
  static const String notificationSent = 'notification.send';

  /// Notification read
  static const String notificationRead = 'notification.read';

  /// Notification deleted
  static const String notificationDeleted = 'notification.deleted';

  // ════════════════════════════════════════════════════════════
  // WebSocket Events
  // ════════════════════════════════════════════════════════════

  /// WebSocket connected
  static const String websocketConnected = 'websocket.connected';

  /// WebSocket disconnected
  static const String websocketDisconnected = 'websocket.disconnected';

  /// WebSocket message received
  static const String websocketMessage = 'websocket.message';

  /// WebSocket error occurred
  static const String websocketError = 'websocket.error';

  /// WebSocket reconnecting
  static const String websocketReconnecting = 'websocket.reconnecting';

  // ════════════════════════════════════════════════════════════
  // Polling Events
  // ════════════════════════════════════════════════════════════

  /// Polling started
  static const String pollingStarted = 'polling.started';

  /// Polling stopped
  static const String pollingStopped = 'polling.stopped';

  /// Change detected during polling
  static const String pollingChangeDetected = 'polling.change_detected';

  /// Polling error
  static const String pollingError = 'polling.error';

  // ════════════════════════════════════════════════════════════
  // Error Events
  // ════════════════════════════════════════════════════════════

  /// General error occurred
  static const String errorOccurred = 'error.occurred';

  /// Network error
  static const String errorNetwork = 'error.network';

  /// Server error
  static const String errorServer = 'error.server';

  /// Validation error
  static const String errorValidation = 'error.validation';

  // ════════════════════════════════════════════════════════════
  // Cache Events
  // ════════════════════════════════════════════════════════════

  /// Cache cleared
  static const String cacheCleared = 'cache.cleared';

  /// Cache item added
  static const String cacheItemAdded = 'cache.item_added';

  /// Cache item removed
  static const String cacheItemRemoved = 'cache.item_removed';

  /// Cache item expired
  static const String cacheItemExpired = 'cache.item_expired';

  // ════════════════════════════════════════════════════════════
  // Utility Methods
  // ════════════════════════════════════════════════════════════

  /// Get all auth event types
  static List<String> get authEvents => [
        authLogin,
        authLogout,
        authTokenRefreshed,
        authTokenRefreshFailed,
        authSessionExpired,
        authLoginFailed,
      ];

  /// Get all odoo event types
  static List<String> get odooEvents => [
        odooRecordCreated,
        odooRecordUpdated,
        odooRecordDeleted,
        odooBatchCompleted,
        odooBatchFailed,
      ];

  /// Get all webhook event types
  static List<String> get webhookEvents => [
        webhookReceived,
        webhookRegistered,
        webhookUnregistered,
        webhookDeliveryFailed,
      ];

  /// Get all sync event types
  static List<String> get syncEvents => [
        updatesAvailable,
        syncStarted,
        syncCompleted,
        syncFailed,
        syncProgress,
        syncCancelled,
        syncPushCompleted,
        syncConflictDetected,
        syncConflictResolved,
        syncStateReset,
        smartSyncCompleted,
      ];

  /// Get all trigger event types
  static List<String> get triggerEvents => [
        triggerExecuted,
        triggerFailed,
        triggerCreated,
        triggerDeleted,
        triggerUpdated,
      ];

  /// Get all notification event types
  static List<String> get notificationEvents => [
        notificationReceived,
        notificationSent,
        notificationRead,
        notificationDeleted,
      ];

  /// Get all websocket event types
  static List<String> get websocketEvents => [
        websocketConnected,
        websocketDisconnected,
        websocketMessage,
        websocketError,
        websocketReconnecting,
      ];

  /// Get all polling event types
  static List<String> get pollingEvents => [
        pollingStarted,
        pollingStopped,
        pollingChangeDetected,
        pollingError,
      ];

  /// Get all error event types
  static List<String> get errorEvents => [
        errorOccurred,
        errorNetwork,
        errorServer,
        errorValidation,
      ];

  /// Get all cache event types
  static List<String> get cacheEvents => [
        cacheCleared,
        cacheItemAdded,
        cacheItemRemoved,
        cacheItemExpired,
      ];

  /// Get all event types
  static List<String> get allEvents => [
        ...authEvents,
        ...odooEvents,
        ...webhookEvents,
        ...syncEvents,
        ...triggerEvents,
        ...notificationEvents,
        ...websocketEvents,
        ...pollingEvents,
        ...errorEvents,
        ...cacheEvents,
      ];
}
