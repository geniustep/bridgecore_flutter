# BridgeCore Flutter SDK v3.0.0

Official Flutter SDK for BridgeCore API - Complete Odoo 18 integration with full sync, triggers, and notifications support.

## 🎉 What's New in v3.0.0

- ✅ **Smart Sync V2** - Efficient sync with only changed records
- ✅ **Offline Sync** - Full offline support with push/pull and conflict resolution
- ✅ **Server-Side Triggers** - Create and manage automation triggers
- ✅ **Notifications API** - Full notification management with device registration
- ✅ **Event Bus** - Central event system for all SDK events
- ✅ **Webhook Events** - Real-time update notifications

## ✨ Features

### Core Features
- ✅ **Easy Authentication** - Login, refresh, logout with automatic token management
- ✅ **33 Odoo Operations** - Complete CRUD, search, advanced, views, permissions, and custom operations
- ✅ **Odoo 18 Context** - Full support for language, timezone, company context
- ✅ **Auto Token Refresh** - Automatic token refresh on expiry
- ✅ **Comprehensive Exceptions** - 10 specialized exception types
- ✅ **Null Safety** - Full null safety support
- ✅ **Type Safe** - Strongly typed models and responses

### Sync Features (NEW in v3.0.0)
- ✅ **Offline Sync** - Push local changes, pull server updates
- ✅ **Smart Sync V2** - Efficient incremental sync
- ✅ **Conflict Resolution** - Resolve sync conflicts
- ✅ **Webhook Events** - Get real-time update notifications
- ✅ **Update Check** - Quick check for available updates
- ✅ **Sync State** - Track sync status per device
- ✅ **Periodic Sync** - Automatic background sync

### Triggers Features (NEW in v3.0.0)
- ✅ **Create Triggers** - Notification, email, webhook, Odoo method triggers
- ✅ **Manage Triggers** - Enable/disable, update, delete triggers
- ✅ **Execute Manually** - Test triggers with specific records
- ✅ **Execution History** - Track trigger executions
- ✅ **Statistics** - Get trigger performance stats

### Notifications Features (NEW in v3.0.0)
- ✅ **List Notifications** - Get user notifications with filtering
- ✅ **Mark as Read** - Single, multiple, or all notifications
- ✅ **Preferences** - Manage notification preferences
- ✅ **Device Registration** - Register devices for push notifications
- ✅ **Statistics** - Notification counts and stats

### Odoo 18 Features
- ✅ **OdooContext Manager** - Global context management
- ✅ **callKw Method** - Generic RPC caller (execute_kw compatible)
- ✅ **7 Action Methods** - Validate, Done, Approve, Reject, Assign, Unlock, ExecuteButton
- ✅ **Action Results** - Parse window actions, reports, URLs
- ✅ **Enhanced Errors** - Detailed error info with codes and data
- ✅ **Arabic Support** - Full RTL and Arabic language support

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  bridgecore_flutter:
    git:
      url: https://github.com/geniustep/bridgecore_flutter.git
      ref: 3.0.0
```

## 🚀 Quick Start

### 1. Initialize SDK

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  // Initialize SDK
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
    debugMode: true,
    enableCache: true,
    enableLogging: true,
    logLevel: LogLevel.info,
  );

  // Set default Odoo 18 context (optional)
  OdooContext.setDefault(
    lang: 'ar_001',
    timezone: 'Asia/Riyadh',
    allowedCompanyIds: [1, 2],
  );

  runApp(MyApp());
}
```

### 2. Login

```dart
try {
  final session = await BridgeCore.instance.auth.login(
    email: 'user@company.com',
    password: 'password123',
  );

  print('Logged in as: ${session.user.fullName}');
  print('User ID: ${session.user.odooUserId}');
} on UnauthorizedException catch (e) {
  print('Login failed: ${e.message}');
}
```

### 3. Use Sync Service

```dart
final sync = BridgeCore.instance.sync;

// Set device info
sync.deviceId = 'device-uuid';
sync.appType = 'sales_app';

// Check for updates
if (await sync.hasUpdates()) {
  // Smart sync (v2) - pulls only new changes
  final result = await sync.smartPull(userId: userId);
  print('Pulled ${result.newEventsCount} new events');
}

// Push local changes
final pushResult = await sync.pushLocalChanges(
  changes: {
    'sale.order': [
      {'id': 1, 'state': 'confirmed', '_action': 'update'},
    ],
  },
);

// Full sync cycle
final fullResult = await sync.fullSyncCycle(
  localChanges: changes,
  models: ['sale.order', 'res.partner'],
);
```

### 4. Use Triggers Service

```dart
final triggers = BridgeCore.instance.triggers;

// Create notification trigger
final trigger = await triggers.create(
  name: 'New Order Alert',
  model: 'sale.order',
  event: TriggerEvent.onCreate,
  actionType: TriggerActionType.notification,
  actionConfig: {
    'title': 'New Order',
    'message': 'Order {{record.name}} created',
    'user_ids': [1, 2, 3],
  },
);

// List triggers
final triggerList = await triggers.list(model: 'sale.order');

// Execute manually
final result = await triggers.execute(
  trigger.id,
  recordIds: [1, 2, 3],
  testMode: true,
);
```

### 5. Use Notifications Service

```dart
final notifications = BridgeCore.instance.notifications;

// Get notifications
final response = await notifications.list(isRead: false);
print('Unread: ${response.unreadCount}');

// Mark as read
await notifications.markAsRead(notificationId);
await notifications.markAllAsRead();

// Update preferences
await notifications.updatePreferences(
  enablePush: true,
  enableEmail: false,
  quietHoursEnabled: true,
);

// Register device
await notifications.registerDevice(
  deviceId: 'device-uuid',
  deviceType: 'android',
  token: 'fcm-token',
);
```

### 6. Use Event Bus

```dart
final eventBus = BridgeCoreEventBus.instance;

// Listen to all events
eventBus.stream.listen((event) {
  print('Event: ${event.type}');
});

// Listen to specific event type
eventBus.on('sync.completed').listen((event) {
  print('Sync completed: ${event.data}');
});

// Listen to pattern
eventBus.onPattern('odoo.').listen((event) {
  print('Odoo event: ${event.type}');
});

// Emit event
eventBus.emit('custom.event', {'key': 'value'});

// Wait for event
final event = await eventBus.waitFor(
  'sync.completed',
  timeout: Duration(seconds: 30),
);
```

## 📖 Complete API Reference

### Authentication (AuthService)

```dart
final auth = BridgeCore.instance.auth;

// Login
final session = await auth.login(email: '...', password: '...');

// Get current user info
final me = await auth.me(forceRefresh: true);
print('Partner ID: ${me.partnerId}');
print('Is Admin: ${me.isAdmin}');

// Refresh token
await auth.refreshToken();

// Logout
await auth.logout();
```

### Odoo Operations (OdooService)

```dart
final odoo = BridgeCore.instance.odoo;

// CRUD Operations
final records = await odoo.searchRead(model: '...', domain: [...]);
final id = await odoo.create(model: '...', values: {...});
await odoo.update(model: '...', ids: [...], values: {...});
await odoo.delete(model: '...', ids: [...]);

// Advanced Operations
final groups = await odoo.advanced.readGroup(...);
final defaults = await odoo.advanced.defaultGet(...);
final onchangeResult = await odoo.advanced.onchange(...);

// View Operations
final view = await odoo.views.getView(...);
final views = await odoo.views.getViews(...);

// Permission Operations
final access = await odoo.permissions.checkAccessRights(...);
final exists = await odoo.permissions.exists(...);

// Custom Operations
final result = await odoo.custom.callKw(...);
await odoo.custom.actionConfirm(...);
await odoo.custom.actionApprove(...);
```

### Sync Service

```dart
final sync = BridgeCore.instance.sync;

// Update Check
bool hasUpdates = await sync.hasUpdates();
List<WebhookEvent> events = await sync.getWebhookEvents();

// Offline Sync
OfflineSyncPullResult pull = await sync.pullUpdates();
OfflineSyncPushResult push = await sync.pushLocalChanges(changes: {...});
ConflictResolutionResult resolve = await sync.resolveConflicts(resolutions: [...]);
OfflineSyncState state = await sync.getSyncState();

// Smart Sync V2
SmartSyncPullResult smartPull = await sync.smartPull(userId: userId);
SmartSyncState smartState = await sync.getSmartSyncState(userId: userId);

// Periodic Sync
sync.startPeriodicUpdateCheck(interval: Duration(minutes: 5));
sync.stopPeriodicUpdateCheck();

// Health Check
SyncHealthStatus health = await sync.checkHealth();
```

### Triggers Service

```dart
final triggers = BridgeCore.instance.triggers;

// Create
Trigger trigger = await triggers.create(
  name: '...',
  model: '...',
  event: TriggerEvent.onCreate,
  actionType: TriggerActionType.notification,
  actionConfig: {...},
);

// List
TriggerListResponse list = await triggers.list();

// Get
Trigger trigger = await triggers.get(triggerId);

// Update
Trigger updated = await triggers.update(triggerId, name: '...');

// Toggle
Trigger toggled = await triggers.toggle(triggerId, true);

// Execute
ManualExecutionResult result = await triggers.execute(triggerId);

// History & Stats
TriggerExecutionListResponse history = await triggers.getHistory(triggerId);
TriggerStats stats = await triggers.getStats(triggerId);

// Delete
bool deleted = await triggers.delete(triggerId);
```

### Notifications Service

```dart
final notifications = BridgeCore.instance.notifications;

// List
NotificationListResponse list = await notifications.list(isRead: false);

// Mark Read
await notifications.markAsRead(notificationId);
await notifications.markMultipleAsRead([id1, id2]);
await notifications.markAllAsRead();

// Delete
await notifications.delete(notificationId);

// Preferences
NotificationPreference prefs = await notifications.getPreferences();
NotificationPreference updated = await notifications.updatePreferences(...);

// Device Registration
DeviceToken token = await notifications.registerDevice(...);
await notifications.unregisterDevice(deviceId);
DeviceTokenListResponse devices = await notifications.listDevices();

// Stats
NotificationStats stats = await notifications.getStats();
```

## 🔄 Event Types

All events emitted by the SDK:

```dart
// Auth Events
'auth.login'
'auth.logout'
'auth.token_refreshed'

// Sync Events
'sync.started'
'sync.completed'
'sync.failed'
'sync.conflict'
'sync.push_completed'
'sync.state_reset'
'updates_available'
'smart_sync.completed'

// Odoo Record Events
'odoo.record_created'
'odoo.record_updated'
'odoo.record_deleted'
```

## 🚨 Error Handling

```dart
try {
  await BridgeCore.instance.auth.login(...);
} on PaymentRequiredException catch (e) {
  print('Trial expired');
} on AccountDeletedException catch (e) {
  print('Account deleted');
} on UnauthorizedException catch (e) {
  print('Unauthorized');
} on TenantSuspendedException catch (e) {
  print('Account suspended');
} on ValidationException catch (e) {
  print('Validation error');
} on NetworkException catch (e) {
  print('No internet');
} on SyncConflictException catch (e) {
  print('Sync conflict: ${e.conflicts}');
} on BridgeCoreException catch (e) {
  print('Error: ${e.message}');
}
```

## 📋 All Endpoints

### Authentication
- `POST /api/v1/auth/tenant/login`
- `POST /api/v1/auth/tenant/refresh`
- `POST /api/v1/auth/tenant/logout`
- `POST /api/v1/auth/tenant/me`

### Odoo Operations
- CRUD: `create`, `read`, `write`, `unlink`
- Search: `search`, `search_read`, `search_count`
- Name: `name_search`, `name_get`, `name_create`
- Advanced: `onchange`, `read_group`, `default_get`, `copy`
- Views: `fields_get`, `fields_view_get`, `get_view`, `load_views`, `get_views`
- Permissions: `check_access_rights`, `exists`
- Custom: `call_kw`, `call_method`
- Batch: `batch_create`, `batch_write`, `batch_unlink`, `batch_execute`
- Web: `web_search_read`, `web_read`, `web_save`

### Sync
- Webhooks: `GET /api/v1/webhooks/check-updates`, `GET /api/v1/webhooks/events`
- Offline Sync: `POST /api/v1/offline-sync/push`, `POST /api/v1/offline-sync/pull`
- Smart Sync: `POST /api/v2/sync/pull`, `GET /api/v2/sync/state`

### Triggers
- `POST /api/v1/triggers/create`
- `GET /api/v1/triggers/list`
- `GET/PUT/DELETE /api/v1/triggers/{id}`
- `POST /api/v1/triggers/{id}/execute`

### Notifications
- `GET /api/v1/notifications/list`
- `POST /api/v1/notifications/{id}/read`
- `GET/PUT /api/v1/notifications/preferences`
- `POST /api/v1/notifications/register-device`

## 🔮 Compatibility

- **Odoo Versions:** 14, 15, 16, 17, 18
- **Flutter:** >=3.0.0
- **Dart:** >=3.0.0

## 📝 Migration from v2.x

All v2.x APIs remain unchanged. New features are additive:

```dart
// v2.x code still works
await odoo.searchRead(...);
await odoo.custom.actionConfirm(...);

// New v3.0.0 features
await BridgeCore.instance.sync.smartPull(...);
await BridgeCore.instance.triggers.create(...);
await BridgeCore.instance.notifications.list();
```

## 🤝 Support

For issues and questions:
- GitHub Issues: https://github.com/geniustep/bridgecore_flutter/issues
- Email: support@geniustep.com

## 📄 License

MIT License

---

**Version:** 3.0.0  
**Last Updated:** 2025-11-28  
**Odoo Compatibility:** 14, 15, 16, 17, 18
