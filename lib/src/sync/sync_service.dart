import 'dart:async';
import 'package:dio/dio.dart';
import '../client/http_client.dart';
import '../core/endpoints.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';

/// Sync Service - Compatible with BridgeCore Backend
///
/// Supports:
/// - /api/v1/webhooks/* - Update checking
/// - /api/v1/offline-sync/* - Full offline sync
/// - /api/v2/sync/* - Smart sync for multi-user apps
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
/// // Smart sync (v2)
/// final result = await sync.smartPull(userId: 'user-123');
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
  /// Uses: GET /api/v1/webhooks/check-updates
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
        BridgeCoreEndpoints.webhookCheckUpdates,
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
  /// Uses: GET /api/v1/webhooks/events
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
        BridgeCoreEndpoints.webhookEvents,
        queryParams: queryParams,
      );

      return (response['events'] as List?)
              ?.map((json) => WebhookEvent.fromJson(json))
              .toList() ??
          [];
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
  /// Uses: POST /api/v1/offline-sync/pull
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
        BridgeCoreEndpoints.offlineSyncPull,
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
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Push local changes to server
  ///
  /// Uses: POST /api/v1/offline-sync/push
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
        BridgeCoreEndpoints.offlineSyncPush,
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
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Resolve sync conflicts
  ///
  /// Uses: POST /api/v1/offline-sync/resolve-conflicts
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
        BridgeCoreEndpoints.offlineSyncResolveConflicts,
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
  /// Uses: GET /api/v1/offline-sync/state
  Future<OfflineSyncState> getSyncState({String? deviceId}) async {
    try {
      final queryParams = {
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      final response = await httpClient.get(
        BridgeCoreEndpoints.offlineSyncState,
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
  /// Uses: POST /api/v1/offline-sync/reset
  Future<bool> resetSyncState({String? deviceId}) async {
    try {
      BridgeCoreLogger.warning('Resetting sync state...');

      final requestBody = {
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.offlineSyncReset,
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
  /// Uses: GET /api/v1/offline-sync/health
  Future<SyncHealthStatus> checkHealth() async {
    try {
      final response = await httpClient.get(
        BridgeCoreEndpoints.offlineSyncHealth,
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
  /// Uses: POST /api/v2/sync/pull
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
    required int userId,
    String? deviceId,
    String? appType,
    List<String>? models,
    int? limit,
  }) async {
    try {
      BridgeCoreLogger.info('Starting smart sync pull (v2)...');

      final requestBody = {
        'user_id': userId,
        'device_id': deviceId ?? this.deviceId ?? 'default',
        if (appType != null || this.appType != null)
          'app_type': appType ?? this.appType,
        if (models != null) 'models': models,
        if (limit != null) 'limit': limit,
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.smartSyncV2Pull,
        requestBody,
      );

      final result = SmartSyncPullResult.fromJson(response);

      _eventBus.emit(BridgeCoreEventTypes.smartSyncCompleted, {
        'user_id': userId,
        'device_id': deviceId ?? this.deviceId,
        'has_updates': result.hasUpdates,
        'new_events_count': result.newEventsCount,
      });

      BridgeCoreLogger.info(
          'Smart sync completed: ${result.newEventsCount} new events');

      return result;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Get smart sync state (v2)
  ///
  /// Uses: GET /api/v2/sync/state
  Future<SmartSyncState> getSmartSyncState({
    required int userId,
    String? deviceId,
  }) async {
    try {
      final queryParams = {
        'user_id': userId.toString(),
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      final response = await httpClient.get(
        BridgeCoreEndpoints.smartSyncV2State,
        queryParams: queryParams,
      );

      return SmartSyncState.fromJson(response);
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Reset smart sync state (v2)
  ///
  /// Uses: POST /api/v2/sync/reset
  Future<bool> resetSmartSyncState({
    required int userId,
    String? deviceId,
  }) async {
    try {
      BridgeCoreLogger.warning('Resetting smart sync state...');

      final queryParams = {
        'user_id': userId.toString(),
        'device_id': deviceId ?? this.deviceId ?? 'default',
      };

      // Build URL with query params
      final url =
          '${BridgeCoreEndpoints.smartSyncV2Reset}?user_id=$userId&device_id=${deviceId ?? this.deviceId ?? 'default'}';

      final response = await httpClient.post(url, {});

      _eventBus.emit(BridgeCoreEventTypes.syncStateReset, {
        'user_id': userId,
        'device_id': deviceId ?? this.deviceId,
        'reset_at': DateTime.now().toIso8601String(),
        'type': 'smart_sync_v2',
      });

      BridgeCoreLogger.info('Smart sync state reset successfully');

      return response['success'] as bool? ?? true;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Check smart sync health (v2)
  ///
  /// Uses: GET /api/v2/sync/health
  Future<SyncHealthStatus> checkSmartSyncHealth() async {
    try {
      final response = await httpClient.get(
        BridgeCoreEndpoints.smartSyncV2Health,
      );

      return SyncHealthStatus.fromJson(response);
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Periodic Update Check
  // ════════════════════════════════════════════════════════════

  /// Start periodic update checking
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
      id: json['id']?.toString() ?? '',
      eventType: json['event_type'] as String? ?? '',
      model: json['model'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
    final dataMap = json['data'] as Map<String, dynamic>? ?? {};
    final convertedData = <String, List<Map<String, dynamic>>>{};

    dataMap.forEach((key, value) {
      if (value is List) {
        convertedData[key] =
            value.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    });

    return OfflineSyncPullResult(
      data: convertedData,
      totalRecords: json['total_records'] as int? ?? 0,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : DateTime.now(),
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
      successful: (json['successful'] as List?)?.cast<String>() ?? [],
      failed: (json['failed'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      conflicts: (json['conflicts'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
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
      resolved: (json['resolved'] as List?)?.cast<String>() ?? [],
      failed: (json['failed'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
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
      deviceId: json['device_id'] as String? ?? 'unknown',
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
  final String? service;
  final String? version;
  final List<String>? features;
  final Map<String, dynamic>? details;

  SyncHealthStatus({
    required this.isHealthy,
    required this.status,
    this.service,
    this.version,
    this.features,
    this.details,
  });

  factory SyncHealthStatus.fromJson(Map<String, dynamic> json) {
    return SyncHealthStatus(
      isHealthy: json['healthy'] as bool? ?? json['status'] == 'healthy',
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String?,
      version: json['version'] as String?,
      features: (json['features'] as List?)?.cast<String>(),
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}

/// Smart Sync Pull Result (V2)
class SmartSyncPullResult {
  final bool hasUpdates;
  final int newEventsCount;
  final List<Map<String, dynamic>> events;
  final String? nextSyncToken;
  final DateTime? lastSyncTime;
  final Map<String, dynamic>? syncState;

  SmartSyncPullResult({
    required this.hasUpdates,
    required this.newEventsCount,
    required this.events,
    this.nextSyncToken,
    this.lastSyncTime,
    this.syncState,
  });

  factory SmartSyncPullResult.fromJson(Map<String, dynamic> json) {
    return SmartSyncPullResult(
      hasUpdates: json['has_updates'] as bool? ?? false,
      newEventsCount: json['new_events_count'] as int? ?? 0,
      events: (json['events'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      nextSyncToken: json['next_sync_token'] as String?,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'] as String)
          : null,
      syncState: json['sync_state'] as Map<String, dynamic>?,
    );
  }
}

/// Smart Sync State (V2)
class SmartSyncState {
  final int userId;
  final String deviceId;
  final int? lastEventId;
  final DateTime? lastSyncAt;
  final int syncCount;
  final String status;
  final Map<String, dynamic>? state;

  SmartSyncState({
    required this.userId,
    required this.deviceId,
    this.lastEventId,
    this.lastSyncAt,
    required this.syncCount,
    required this.status,
    this.state,
  });

  factory SmartSyncState.fromJson(Map<String, dynamic> json) {
    return SmartSyncState(
      userId: json['user_id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? 'unknown',
      lastEventId: json['last_event_id'] as int?,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      syncCount: json['sync_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
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
    super.message, {
    super.statusCode,
    this.conflicts,
  });
}
