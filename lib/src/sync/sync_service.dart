import 'dart:async';
import 'package:dio/dio.dart';
import '../client/http_client.dart';
import '../core/endpoints.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';

/// Sync Service - Compatible with BridgeCore Backend v1
///
/// ⚠️ IMPORTANT: This service uses the ACTUAL endpoints from BridgeCore:
/// - /api/v1/webhooks/check-updates (✅ exists)
/// - /api/v1/offline-sync/* (✅ exists - full sync system)
/// - /api/v2/sync/* (✅ exists - smart sync system)
///
/// Usage:
/// ```dart
/// final sync = BridgeCore.instance.sync;
///
/// // Quick check for updates
/// if (await sync.hasUpdates()) {
///   print('Updates available!');
/// }
///
/// // Start offline sync (push/pull)
/// await sync.pullUpdates();
/// await sync.pushLocalChanges(changes);
///
/// // Check sync state
/// final state = await sync.getSyncState(deviceId: 'device-123');
/// ```
class SyncService {
  final BridgeCoreHttpClient httpClient;
  final BridgeCoreEventBus _eventBus = BridgeCoreEventBus.instance;

  /// Current sync state cache
  OfflineSyncState? _cachedState;

  /// Periodic update checker timer
  Timer? _updateCheckTimer;

  /// Update check interval
  Duration _updateCheckInterval = const Duration(minutes: 5);

  /// Default device ID (should be set by app)
  String? deviceId;

  /// Default app type (sales_app, delivery_app, etc.)
  String? appType;

  SyncService({
    required this.httpClient,
    this.deviceId,
    this.appType,
  });

  // ════════════════════════════════════════════════════════════
  // Update Check Methods (using /api/v1/webhooks/*)
  // ════════════════════════════════════════════════════════════

  /// Check if updates are available (quick check)
  ///
  /// Uses: GET /api/v1/webhooks/check-updates ✅
  ///
  /// Example:
  /// ```dart
  /// if (await sync.hasUpdates()) {
  ///   showUpdateNotification();
  /// }
  /// ```
  Future<bool> hasUpdates({
    String? userId,
    String? deviceId,
    String? appType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (deviceId != null) queryParams['device_id'] = deviceId;
      if (appType != null) queryParams['app_type'] = appType;

      final response = await httpClient.get(
        BridgeCoreEndpoints
            .webhookCheckUpdates, // ✅ /api/v1/webhooks/check-updates
        queryParams: queryParams,
      );

      final hasUpdate = response['has_updates'] as bool? ?? false;
      final pendingCount = response['pending_events'] as int? ?? 0;

      if (hasUpdate) {
        _eventBus.emit(BridgeCoreEventTypes.updatesAvailable, {
          'checked_at': DateTime.now().toIso8601String(),
          'pending_count': pendingCount,
          'last_event_id': response['last_event_id'],
        });

        BridgeCoreLogger.info(
            'Updates available: $pendingCount pending events');
      }

      return hasUpdate;
    } on DioException catch (e) {
      _handleSyncError(e);
      return false;
    }
  }

  /// Get webhook events (detailed updates)
  ///
  /// Uses: GET /api/v1/webhooks/events ✅
  ///
  /// Example:
  /// ```dart
  /// final events = await sync.getWebhookEvents(
  ///   model: 'sale.order',
  ///   limit: 50,
  /// );
  ///
  /// for (var event in events) {
  ///   print('Event: ${event.eventType} - ${event.model}');
  /// }
  /// ```
  Future<List<WebhookEvent>> getWebhookEvents({
    String? model,
    String? eventType,
    String? status,
    int? limit,
    int? offset,
    DateTime? since,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (model != null) queryParams['model'] = model;
      if (eventType != null) queryParams['event_type'] = eventType;
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (since != null) queryParams['since'] = since.toIso8601String();

      final response = await httpClient.get(
        BridgeCoreEndpoints.webhookEvents, // ✅ /api/v1/webhooks/events
        queryParams: queryParams,
      );

      return (response['events'] as List)
          .map((json) => WebhookEvent.fromJson(json))
          .toList();
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Offline Sync Methods (using /api/v1/offline-sync/*)
  // ════════════════════════════════════════════════════════════

  /// Pull updates from server
  ///
  /// Uses: POST /api/v1/offline-sync/pull ✅
  ///
  /// Example:
  /// ```dart
  /// final result = await sync.pullUpdates(
  ///   deviceId: 'device-123',
  ///   models: ['sale.order', 'product.product'],
  /// );
  ///
  /// print('Pulled ${result.totalRecords} records');
  /// ```
  Future<OfflineSyncPullResult> pullUpdates({
    String? deviceId,
    List<String>? models,
    DateTime? since,
    int? batchSize,
  }) async {
    try {
      BridgeCoreLogger.info('Pulling updates from server...');

      final requestBody = <String, dynamic>{
        'device_id': deviceId ?? this.deviceId ?? 'default',
        if (models != null) 'models': models,
        if (since != null) 'since': since.toIso8601String(),
        if (batchSize != null) 'batch_size': batchSize,
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.offlineSyncPull, // ✅ /api/v1/offline-sync/pull
        requestBody,
      );

      final result = OfflineSyncPullResult.fromJson(response);

      _eventBus.emit(BridgeCoreEventTypes.syncCompleted, {
        'device_id': deviceId ?? this.deviceId,
        'total_records': result.totalRecords,
        'models': result.data.keys.toList(),
        'pulled_at': DateTime.now().toIso8601String(),
      });

      BridgeCoreLogger.info(
        'Pull completed: ${result.totalRecords} records from ${result.data.length} models',
      );

      return result;
    } on DioException catch (e) {
      // _eventBus.emit(BridgeCoreEventTypes.syncPullFailed, {
      //   'error': e.toString(),
      // });
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Push local changes to server
  ///
  /// Uses: POST /api/v1/offline-sync/push ✅
  ///
  /// Example:
  /// ```dart
  /// final changes = {
  ///   'sale.order': [
  ///     {
  ///       'id': 123,
  ///       'local_id': 'temp-456',
  ///       'operation': 'create',
  ///       'data': {'name': 'SO001', 'amount': 1000},
  ///       'timestamp': DateTime.now().toIso8601String(),
  ///     }
  ///   ],
  /// };
  ///
  /// final result = await sync.pushLocalChanges(changes);
  /// print('Pushed successfully: ${result.successful.length}');
  /// ```
  Future<OfflineSyncPushResult> pushLocalChanges({
    required Map<String, List<Map<String, dynamic>>> changes,
    String? deviceId,
  }) async {
    try {
      BridgeCoreLogger.info('Pushing local changes to server...');

      final requestBody = {
        'device_id': deviceId ?? this.deviceId ?? 'default',
        'changes': changes,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.offlineSyncPush, // ✅ /api/v1/offline-sync/push
        requestBody,
      );

      final result = OfflineSyncPushResult.fromJson(response);

      if (result.conflicts.isNotEmpty) {
        _eventBus.emit(BridgeCoreEventTypes.syncConflictDetected, {
          'conflict_count': result.conflicts.length,
          'conflicts': result.conflicts,
        });

        BridgeCoreLogger.warning(
          'Push completed with ${result.conflicts.length} conflicts',
        );
      }

      _eventBus.emit(BridgeCoreEventTypes.syncPushCompleted, {
        'device_id': deviceId ?? this.deviceId,
        'successful': result.successful.length,
        'failed': result.failed.length,
        'conflicts': result.conflicts.length,
        'pushed_at': DateTime.now().toIso8601String(),
      });

      BridgeCoreLogger.info(
        'Push completed: ${result.successful.length} successful, '
        '${result.failed.length} failed, ${result.conflicts.length} conflicts',
      );

      return result;
    } on DioException catch (e) {
      // _eventBus.emit(BridgeCoreEventTypes. syncPushFailed, {
      //   'error': e.toString(),
      // });
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Resolve sync conflicts
  ///
  /// Uses: POST /api/v1/offline-sync/resolve-conflicts ✅
  ///
  /// Example:
  /// ```dart
  /// final resolutions = [
  ///   {
  ///     'conflict_id': 'conf-123',
  ///     'resolution': 'use_server', // or 'use_local', 'merge'
  ///     'merged_data': {...}, // if resolution = 'merge'
  ///   }
  /// ];
  ///
  /// final result = await sync.resolveConflicts(resolutions);
  /// ```
  Future<ConflictResolutionResult> resolveConflicts({
    required List<Map<String, dynamic>> resolutions,
    String? deviceId,
  }) async {
    try {
      BridgeCoreLogger.info('Resolving ${resolutions.length} conflicts...');

      final requestBody = {
        'device_id': deviceId ?? this.deviceId ?? 'default',
        'resolutions': resolutions,
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints
            .offlineSyncResolveConflicts, // ✅ /api/v1/offline-sync/resolve-conflicts
        requestBody,
      );

      final result = ConflictResolutionResult.fromJson(response);

      _eventBus.emit(BridgeCoreEventTypes.syncConflictResolved, {
        'resolved_count': result.resolved.length,
        'failed_count': result.failed.length,
      });

      BridgeCoreLogger.info(
        'Conflicts resolved: ${result.resolved.length} successful, '
        '${result.failed.length} failed',
      );

      return result;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Get offline sync state
  ///
  /// Uses: GET /api/v1/offline-sync/state?device_id=xxx ✅
  ///
  /// Example:
  /// ```dart
  /// final state = await sync.getSyncState(deviceId: 'device-123');
  /// print('Last sync: ${state.lastSyncAt}');
  /// print('Pending changes: ${state.pendingChanges}');
  /// ```
  Future<OfflineSyncState> getSyncState({String? deviceId}) async {
    try {
      final queryParams = {
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      final response = await httpClient.get(
        BridgeCoreEndpoints.offlineSyncState, // ✅ /api/v1/offline-sync/state
        queryParams: queryParams,
      );

      _cachedState = OfflineSyncState.fromJson(response);
      return _cachedState!;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Reset sync state (use with caution!)
  ///
  /// Uses: POST /api/v1/offline-sync/reset ✅
  ///
  /// Example:
  /// ```dart
  /// await sync.resetSyncState(deviceId: 'device-123');
  /// ```
  Future<bool> resetSyncState({String? deviceId}) async {
    try {
      BridgeCoreLogger.warning('Resetting sync state...');

      final requestBody = {
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.offlineSyncReset, // ✅ /api/v1/offline-sync/reset
        requestBody,
      );

      _cachedState = null;

      _eventBus.emit(BridgeCoreEventTypes.syncStateReset, {
        'device_id': deviceId ?? this.deviceId,
        'reset_at': DateTime.now().toIso8601String(),
      });

      BridgeCoreLogger.info('Sync state reset successfully');

      return response['success'] as bool? ?? true;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Check offline sync health
  ///
  /// Uses: GET /api/v1/offline-sync/health ✅
  ///
  /// Example:
  /// ```dart
  /// final health = await sync.checkHealth();
  /// if (health.isHealthy) {
  ///   print('Sync system is healthy');
  /// }
  /// ```
  Future<SyncHealthStatus> checkHealth() async {
    try {
      final response = await httpClient.get(
        BridgeCoreEndpoints.offlineSyncHealth, // ✅ /api/v1/offline-sync/health
      );

      return SyncHealthStatus.fromJson(response);
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Smart Sync V2 Methods (using /api/v2/sync/*)
  // ════════════════════════════════════════════════════════════

  /// Smart sync pull (v2)
  ///
  /// Uses: POST /api/v2/sync/pull ✅
  ///
  /// Example:
  /// ```dart
  /// final result = await sync.smartPull(
  ///   userId: 'user-123',
  ///   deviceId: 'device-456',
  ///   appType: 'sales_app',
  /// );
  /// ```
  Future<SmartSyncPullResult> smartPull({
    required String userId,
    String? deviceId,
    String? appType,
    List<String>? models,
  }) async {
    try {
      BridgeCoreLogger.info('Starting smart sync pull (v2)...');

      final requestBody = {
        'user_id': userId,
        'device_id': deviceId ?? this.deviceId ?? 'default',
        if (appType != null || this.appType != null)
          'app_type': appType ?? this.appType,
        if (models != null) 'models': models,
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.smartSyncV2Pull, // ✅ /api/v2/sync/pull
        requestBody,
      );

      final result = SmartSyncPullResult.fromJson(response);

      _eventBus.emit(BridgeCoreEventTypes.smartSyncCompleted, {
        'user_id': userId,
        'device_id': deviceId ?? this.deviceId,
        'total_updates': result.totalUpdates,
      });

      BridgeCoreLogger.info(
          'Smart sync completed: ${result.totalUpdates} updates');

      return result;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Get smart sync state (v2)
  ///
  /// Uses: GET /api/v2/sync/state?user_id=xxx&device_id=xxx ✅
  ///
  /// Example:
  /// ```dart
  /// final state = await sync.getSmartSyncState(
  ///   userId: 'user-123',
  ///   deviceId: 'device-456',
  /// );
  /// ```
  Future<SmartSyncState> getSmartSyncState({
    required String userId,
    String? deviceId,
  }) async {
    try {
      final queryParams = {
        'user_id': userId,
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      final response = await httpClient.get(
        BridgeCoreEndpoints.smartSyncV2State, // ✅ /api/v2/sync/state
        queryParams: queryParams,
      );

      return SmartSyncState.fromJson(response);
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Periodic Update Check
  // ════════════════════════════════════════════════════════════

  /// Start periodic update checking
  ///
  /// Example:
  /// ```dart
  /// sync.startPeriodicUpdateCheck(
  ///   interval: Duration(minutes: 5),
  ///   userId: 'user-123',
  /// );
  ///
  /// // Listen for updates
  /// BridgeCoreEventBus.instance.on('updates.available').listen((event) {
  ///   showUpdateNotification();
  /// });
  /// ```
  void startPeriodicUpdateCheck({
    Duration? interval,
    String? userId,
    String? deviceId,
    String? appType,
  }) {
    stopPeriodicUpdateCheck();

    if (interval != null) {
      _updateCheckInterval = interval;
    }

    BridgeCoreLogger.info(
      'Starting periodic update check (interval: ${_updateCheckInterval.inMinutes}m)',
    );

    _updateCheckTimer = Timer.periodic(_updateCheckInterval, (_) async {
      try {
        await hasUpdates(
          userId: userId,
          deviceId: deviceId ?? this.deviceId,
          appType: appType ?? this.appType,
        );
      } catch (e) {
        BridgeCoreLogger.error('Periodic update check failed', null, e);
      }
    });
  }

  /// Stop periodic update checking
  void stopPeriodicUpdateCheck() {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = null;
    BridgeCoreLogger.info('Stopped periodic update check');
  }

  /// Check if periodic update check is active
  bool get isPeriodicUpdateCheckActive => _updateCheckTimer?.isActive ?? false;

  // ════════════════════════════════════════════════════════════
  // Utility Methods
  // ════════════════════════════════════════════════════════════

  /// Get cached sync state (no API call)
  OfflineSyncState? get cachedState => _cachedState;

  /// Full sync cycle (push local changes, then pull updates)
  ///
  /// Example:
  /// ```dart
  /// final result = await sync.fullSyncCycle(
  ///   localChanges: myChanges,
  ///   deviceId: 'device-123',
  /// );
  ///
  /// if (result.hasConflicts) {
  ///   // Handle conflicts
  ///   await resolveConflicts(resolutions: myResolutions);
  /// }
  /// ```
  Future<FullSyncResult> fullSyncCycle({
    required Map<String, List<Map<String, dynamic>>> localChanges,
    String? deviceId,
    List<String>? models,
  }) async {
    try {
      BridgeCoreLogger.info('Starting full sync cycle...');

      _eventBus.emit(BridgeCoreEventTypes.syncStarted, {
        'device_id': deviceId ?? this.deviceId,
        'started_at': DateTime.now().toIso8601String(),
      });

      // Step 1: Push local changes
      final pushResult = await pushLocalChanges(
        changes: localChanges,
        deviceId: deviceId,
      );

      // Step 2: Pull server updates
      final pullResult = await pullUpdates(
        deviceId: deviceId,
        models: models,
      );

      // Step 3: Get final state
      final finalState = await getSyncState(deviceId: deviceId);

      final fullResult = FullSyncResult(
        pushResult: pushResult,
        pullResult: pullResult,
        finalState: finalState,
      );

      _eventBus.emit(BridgeCoreEventTypes.syncCompleted, {
        'device_id': deviceId ?? this.deviceId,
        'has_conflicts': fullResult.hasConflicts,
        'completed_at': DateTime.now().toIso8601String(),
      });

      BridgeCoreLogger.info('Full sync cycle completed');

      return fullResult;
    } catch (e) {
      _eventBus.emit(BridgeCoreEventTypes.syncFailed, {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    stopPeriodicUpdateCheck();
    _cachedState = null;
  }

  // ════════════════════════════════════════════════════════════
  // Error Handling
  // ════════════════════════════════════════════════════════════

  void _handleSyncError(DioException error) {
    final message = error.response?.data?['message'] ??
        error.response?.data?['detail'] ??
        error.message;

    BridgeCoreLogger.error('Sync error: $message', null, error);

    // Emit error event
    _eventBus.emit(BridgeCoreEventTypes.syncFailed, {
      'error': message,
      'status_code': error.response?.statusCode,
      'endpoint': error.requestOptions.path,
    });

    // Throw appropriate exception
    if (error.response?.statusCode == 401) {
      throw UnauthorizedException(
        message ?? 'Unauthorized',
        statusCode: 401,
        endpoint: error.requestOptions.path,
        method: error.requestOptions.method,
      );
    } else if (error.response?.statusCode == 409) {
      // Conflict error (usually sync conflicts)
      throw SyncConflictException(
        message ?? 'Sync conflict detected',
        statusCode: 409,
        conflicts: error.response?.data?['conflicts'],
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      throw NetworkException(
        'Sync timeout: $message',
        originalError: error,
      );
    } else {
      throw BridgeCoreException(
        message ?? 'Sync failed',
        statusCode: error.response?.statusCode,
        endpoint: error.requestOptions.path,
        method: error.requestOptions.method,
      );
    }
  }
}

// ════════════════════════════════════════════════════════════
// Data Models
// ════════════════════════════════════════════════════════════

/// Webhook Event
class WebhookEvent {
  final String id;
  final String eventType;
  final String model;
  final Map<String, dynamic> data;
  final String status;
  final DateTime createdAt;

  WebhookEvent({
    required this.id,
    required this.eventType,
    required this.model,
    required this.data,
    required this.status,
    required this.createdAt,
  });

  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      id: json['id'] as String,
      eventType: json['event_type'] as String,
      model: json['model'] as String,
      data: json['data'] as Map<String, dynamic>,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Offline Sync Pull Result
class OfflineSyncPullResult {
  final Map<String, List<Map<String, dynamic>>> data;
  final int totalRecords;
  final DateTime syncedAt;

  OfflineSyncPullResult({
    required this.data,
    required this.totalRecords,
    required this.syncedAt,
  });

  factory OfflineSyncPullResult.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>;
    final convertedData = <String, List<Map<String, dynamic>>>{};

    dataMap.forEach((key, value) {
      convertedData[key] =
          (value as List).map((e) => e as Map<String, dynamic>).toList();
    });

    return OfflineSyncPullResult(
      data: convertedData,
      totalRecords: json['total_records'] as int? ?? 0,
      syncedAt: DateTime.parse(json['synced_at'] as String),
    );
  }
}

/// Offline Sync Push Result
class OfflineSyncPushResult {
  final List<String> successful;
  final List<Map<String, dynamic>> failed;
  final List<Map<String, dynamic>> conflicts;

  OfflineSyncPushResult({
    required this.successful,
    required this.failed,
    required this.conflicts,
  });

  factory OfflineSyncPushResult.fromJson(Map<String, dynamic> json) {
    return OfflineSyncPushResult(
      successful: (json['successful'] as List).cast<String>(),
      failed: (json['failed'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      conflicts: (json['conflicts'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

/// Conflict Resolution Result
class ConflictResolutionResult {
  final List<String> resolved;
  final List<Map<String, dynamic>> failed;

  ConflictResolutionResult({
    required this.resolved,
    required this.failed,
  });

  factory ConflictResolutionResult.fromJson(Map<String, dynamic> json) {
    return ConflictResolutionResult(
      resolved: (json['resolved'] as List).cast<String>(),
      failed: (json['failed'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

/// Offline Sync State
class OfflineSyncState {
  final String deviceId;
  final DateTime? lastSyncAt;
  final int pendingChanges;
  final Map<String, dynamic>? metadata;

  OfflineSyncState({
    required this.deviceId,
    this.lastSyncAt,
    required this.pendingChanges,
    this.metadata,
  });

  factory OfflineSyncState.fromJson(Map<String, dynamic> json) {
    return OfflineSyncState(
      deviceId: json['device_id'] as String,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      pendingChanges: json['pending_changes'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Sync Health Status
class SyncHealthStatus {
  final bool isHealthy;
  final String status;
  final Map<String, dynamic>? details;

  SyncHealthStatus({
    required this.isHealthy,
    required this.status,
    this.details,
  });

  factory SyncHealthStatus.fromJson(Map<String, dynamic> json) {
    return SyncHealthStatus(
      isHealthy: json['healthy'] as bool? ?? false,
      status: json['status'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}

/// Smart Sync Pull Result (V2)
class SmartSyncPullResult {
  final Map<String, dynamic> updates;
  final int totalUpdates;
  final DateTime syncedAt;

  SmartSyncPullResult({
    required this.updates,
    required this.totalUpdates,
    required this.syncedAt,
  });

  factory SmartSyncPullResult.fromJson(Map<String, dynamic> json) {
    return SmartSyncPullResult(
      updates: json['updates'] as Map<String, dynamic>,
      totalUpdates: json['total_updates'] as int? ?? 0,
      syncedAt: DateTime.parse(json['synced_at'] as String),
    );
  }
}

/// Smart Sync State (V2)
class SmartSyncState {
  final String userId;
  final String deviceId;
  final DateTime? lastSyncAt;
  final Map<String, dynamic>? state;

  SmartSyncState({
    required this.userId,
    required this.deviceId,
    this.lastSyncAt,
    this.state,
  });

  factory SmartSyncState.fromJson(Map<String, dynamic> json) {
    return SmartSyncState(
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      state: json['state'] as Map<String, dynamic>?,
    );
  }
}

/// Full Sync Result (combined push + pull)
class FullSyncResult {
  final OfflineSyncPushResult pushResult;
  final OfflineSyncPullResult pullResult;
  final OfflineSyncState finalState;

  FullSyncResult({
    required this.pushResult,
    required this.pullResult,
    required this.finalState,
  });

  bool get hasConflicts => pushResult.conflicts.isNotEmpty;
  bool get hasFailures => pushResult.failed.isNotEmpty;
  int get totalPulled => pullResult.totalRecords;
  int get totalPushed => pushResult.successful.length;
}

/// Sync Conflict Exception
class SyncConflictException extends BridgeCoreException {
  final List<Map<String, dynamic>>? conflicts;

  SyncConflictException(
    String message, {
    int? statusCode,
    this.conflicts,
  }) : super(
          message,
          statusCode: statusCode,
        );
}
