/// Odoo Sync Service
///
/// Direct integration with auto-webhook-odoo module via BridgeCore.
/// Provides methods for pulling events, managing sync states, and
/// synchronizing data between Flutter apps and Odoo.
library;

import 'dart:async';
import 'package:dio/dio.dart';
import '../core/http_client.dart';
import '../core/endpoints.dart';
import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';

/// Odoo Sync Service
///
/// Handles synchronization with Odoo's update.webhook table via BridgeCore.
class OdooSyncService {
  final BridgeCoreHttpClient _httpClient;
  final BridgeCoreEventBus _eventBus;
  String? _deviceId;

  OdooSyncService(this._httpClient, this._eventBus);

  /// Set device ID for sync state tracking
  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// Get current device ID
  String? get deviceId => _deviceId;

  // ════════════════════════════════════════════════════════════
  // Pull Events
  // ════════════════════════════════════════════════════════════

  /// Pull events from Odoo's update.webhook table
  ///
  /// Uses: POST /api/v1/odoo-sync/pull
  Future<OdooPullResult> pullEvents({
    int lastEventId = 0,
    int limit = 100,
    List<String>? models,
    String? priority,
    String? appType,
  }) async {
    try {
      BridgeCoreLogger.info('Pulling events from Odoo (last_id: $lastEventId)');

      final response = await _httpClient.post(
        BridgeCoreEndpoints.odooSyncPull,
        {
          'last_event_id': lastEventId,
          'limit': limit,
          if (models != null) 'models': models,
          if (priority != null) 'priority': priority,
          if (appType != null) 'app_type': appType,
        },
      );

      final result = OdooPullResult.fromJson(response);

      if (result.events.isNotEmpty) {
        _eventBus.emit(BridgeCoreEventTypes.odooEventsPulled, {
          'count': result.count,
          'last_id': result.lastId,
          'has_more': result.hasMore,
        });
      }

      BridgeCoreLogger.info(
        'Pulled ${result.count} events from Odoo',
      );

      return result;
    } on DioException catch (e) {
      BridgeCoreLogger.error('Failed to pull events from Odoo', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Acknowledge Events
  // ════════════════════════════════════════════════════════════

  /// Acknowledge events as processed
  ///
  /// Uses: POST /api/v1/odoo-sync/ack
  Future<OdooAckResult> acknowledgeEvents(List<int> eventIds) async {
    try {
      if (eventIds.isEmpty) {
        return OdooAckResult(
          success: true,
          processedCount: 0,
          message: 'No events to acknowledge',
        );
      }

      BridgeCoreLogger.info('Acknowledging ${eventIds.length} events');

      final response = await _httpClient.post(
        BridgeCoreEndpoints.odooSyncAck,
        {'event_ids': eventIds},
      );

      return OdooAckResult.fromJson(response);
    } on DioException catch (e) {
      BridgeCoreLogger.error('Failed to acknowledge events', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Sync State Management
  // ════════════════════════════════════════════════════════════

  /// Get or create sync state for user/device
  ///
  /// Uses: POST /api/v1/odoo-sync/sync-state
  Future<OdooSyncState> getSyncState({
    required int userId,
    required String deviceId,
    String appType = 'mobile_app',
    String? deviceInfo,
    String? appVersion,
  }) async {
    try {
      BridgeCoreLogger.info('Getting sync state for user $userId');

      final response = await _httpClient.post(
        BridgeCoreEndpoints.odooSyncState,
        {
          'user_id': userId,
          'device_id': deviceId,
          'app_type': appType,
          if (deviceInfo != null) 'device_info': deviceInfo,
          if (appVersion != null) 'app_version': appVersion,
        },
      );

      final syncState = OdooSyncState.fromJson(response['sync_state']);

      _eventBus.emit(BridgeCoreEventTypes.syncStateUpdated, {
        'user_id': userId,
        'device_id': deviceId,
        'last_event_id': syncState.lastEventId,
      });

      return syncState;
    } on DioException catch (e) {
      BridgeCoreLogger.error('Failed to get sync state', e);
      rethrow;
    }
  }

  /// Update sync state after pulling events
  ///
  /// Uses: POST /api/v1/odoo-sync/sync-state/update
  Future<OdooSyncState> updateSyncState({
    required int userId,
    required String deviceId,
    required int lastEventId,
    int eventsSynced = 0,
  }) async {
    try {
      BridgeCoreLogger.info(
        'Updating sync state: user=$userId, last_event=$lastEventId',
      );

      final response = await _httpClient.post(
        BridgeCoreEndpoints.odooSyncStateUpdate,
        {
          'user_id': userId,
          'device_id': deviceId,
          'last_event_id': lastEventId,
          'events_synced': eventsSynced,
        },
      );

      final syncState = OdooSyncState.fromJson(response['sync_state']);

      _eventBus.emit(BridgeCoreEventTypes.syncStateUpdated, {
        'user_id': userId,
        'device_id': deviceId,
        'last_event_id': syncState.lastEventId,
        'sync_count': syncState.syncCount,
      });

      return syncState;
    } on DioException catch (e) {
      BridgeCoreLogger.error('Failed to update sync state', e);
      rethrow;
    }
  }

  /// Get sync statistics for user
  ///
  /// Uses: GET /api/v1/odoo-sync/sync-state/stats
  Future<OdooSyncStatistics> getSyncStatistics({
    required int userId,
    String? deviceId,
    String? appType,
  }) async {
    try {
      final queryParams = {
        'user_id': userId.toString(),
        if (deviceId != null) 'device_id': deviceId,
        if (appType != null) 'app_type': appType,
      };

      final response = await _httpClient.get(
        BridgeCoreEndpoints.odooSyncStateStats,
        queryParams: queryParams,
      );

      return OdooSyncStatistics.fromJson(response['stats']);
    } on DioException catch (e) {
      BridgeCoreLogger.error('Failed to get sync statistics', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Smart Pull (Convenience Method)
  // ════════════════════════════════════════════════════════════

  /// Smart pull: Get state → Pull events → Update state
  ///
  /// Uses: POST /api/v1/odoo-sync/smart-pull
  Future<OdooSmartPullResult> smartPull({
    required int userId,
    required String deviceId,
    String appType = 'mobile_app',
    int limit = 100,
    bool autoAck = true,
  }) async {
    try {
      BridgeCoreLogger.info('Smart pull for user $userId');

      final queryParams = {
        'user_id': userId.toString(),
        'device_id': deviceId,
        'app_type': appType,
        'limit': limit.toString(),
        'auto_ack': autoAck.toString(),
      };

      // Build URL with query params
      final url = '${BridgeCoreEndpoints.odooSyncSmartPull}?'
          '${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await _httpClient.post(url, {});

      final result = OdooSmartPullResult.fromJson(response);

      if (result.count > 0) {
        _eventBus.emit(BridgeCoreEventTypes.odooEventsPulled, {
          'count': result.count,
          'last_id': result.lastId,
          'has_more': result.hasMore,
          'method': 'smart_pull',
        });
      }

      BridgeCoreLogger.info(
        'Smart pull completed: ${result.count} events',
      );

      return result;
    } on DioException catch (e) {
      BridgeCoreLogger.error('Smart pull failed', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Health & Statistics
  // ════════════════════════════════════════════════════════════

  /// Check Odoo sync health
  ///
  /// Uses: GET /api/v1/odoo-sync/health
  Future<OdooSyncHealth> checkHealth() async {
    try {
      final response = await _httpClient.get(
        BridgeCoreEndpoints.odooSyncHealth,
      );

      return OdooSyncHealth.fromJson(response);
    } on DioException catch (e) {
      BridgeCoreLogger.error('Health check failed', e);
      return OdooSyncHealth(
        status: 'error',
        odooConnected: false,
        pendingEvents: 0,
      );
    }
  }

  /// Get Odoo webhook statistics
  ///
  /// Uses: GET /api/v1/odoo-sync/stats
  Future<Map<String, dynamic>> getStatistics({int days = 7}) async {
    try {
      final response = await _httpClient.get(
        BridgeCoreEndpoints.odooSyncStats,
        queryParams: {'days': days.toString()},
      );

      return response['stats'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      BridgeCoreLogger.error('Failed to get statistics', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Full Sync Workflow
  // ════════════════════════════════════════════════════════════

  /// Perform a full sync cycle
  ///
  /// 1. Get sync state to find last_event_id
  /// 2. Pull all new events (with pagination)
  /// 3. Acknowledge events
  /// 4. Update sync state
  Future<OdooFullSyncResult> fullSync({
    required int userId,
    required String deviceId,
    String appType = 'mobile_app',
    int batchSize = 100,
    void Function(int pulled, int total)? onProgress,
  }) async {
    try {
      BridgeCoreLogger.info('Starting full sync for user $userId');

      final allEvents = <OdooEvent>[];
      var hasMore = true;
      var totalPulled = 0;

      // Get initial sync state
      final syncState = await getSyncState(
        userId: userId,
        deviceId: deviceId,
        appType: appType,
      );

      var lastEventId = syncState.lastEventId;

      // Pull all events with pagination
      while (hasMore) {
        final result = await pullEvents(
          lastEventId: lastEventId,
          limit: batchSize,
          appType: appType,
        );

        if (result.events.isEmpty) break;

        allEvents.addAll(result.events);
        totalPulled += result.count;
        lastEventId = result.lastId;
        hasMore = result.hasMore;

        // Acknowledge batch
        final eventIds = result.events.map((e) => e.id).toList();
        await acknowledgeEvents(eventIds);

        // Progress callback
        onProgress?.call(totalPulled, -1);

        BridgeCoreLogger.debug(
          'Full sync progress: pulled $totalPulled events',
        );
      }

      // Update final sync state
      final updatedState = await updateSyncState(
        userId: userId,
        deviceId: deviceId,
        lastEventId: lastEventId,
        eventsSynced: totalPulled,
      );

      _eventBus.emit(BridgeCoreEventTypes.syncCompleted, {
        'user_id': userId,
        'device_id': deviceId,
        'total_events': totalPulled,
        'method': 'full_sync',
      });

      BridgeCoreLogger.info(
        'Full sync completed: $totalPulled events synced',
      );

      return OdooFullSyncResult(
        success: true,
        events: allEvents,
        totalSynced: totalPulled,
        syncState: updatedState,
      );
    } catch (e) {
      BridgeCoreLogger.error('Full sync failed', e);
      return OdooFullSyncResult(
        success: false,
        events: [],
        totalSynced: 0,
        error: e.toString(),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════
// Data Models
// ════════════════════════════════════════════════════════════

/// Single event from Odoo
class OdooEvent {
  final int id;
  final String model;
  final int recordId;
  final String event;
  final DateTime? timestamp;
  final Map<String, dynamic>? payload;
  final String? priority;
  final String? category;
  final int? userId;
  final String? userName;

  OdooEvent({
    required this.id,
    required this.model,
    required this.recordId,
    required this.event,
    this.timestamp,
    this.payload,
    this.priority,
    this.category,
    this.userId,
    this.userName,
  });

  factory OdooEvent.fromJson(Map<String, dynamic> json) {
    return OdooEvent(
      id: json['id'] as int,
      model: json['model'] as String,
      recordId: json['record_id'] as int,
      event: json['event'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      payload: json['payload'] as Map<String, dynamic>?,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'model': model,
        'record_id': recordId,
        'event': event,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        if (payload != null) 'payload': payload,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
        if (userId != null) 'user_id': userId,
        if (userName != null) 'user_name': userName,
      };
}

/// Result from pulling events
class OdooPullResult {
  final bool success;
  final List<OdooEvent> events;
  final int lastId;
  final bool hasMore;
  final int count;
  final DateTime? timestamp;

  OdooPullResult({
    required this.success,
    required this.events,
    required this.lastId,
    required this.hasMore,
    required this.count,
    this.timestamp,
  });

  factory OdooPullResult.fromJson(Map<String, dynamic> json) {
    return OdooPullResult(
      success: json['success'] as bool? ?? true,
      events: (json['events'] as List?)
              ?.map((e) => OdooEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastId: json['last_id'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

/// Result from acknowledging events
class OdooAckResult {
  final bool success;
  final int processedCount;
  final String message;

  OdooAckResult({
    required this.success,
    required this.processedCount,
    required this.message,
  });

  factory OdooAckResult.fromJson(Map<String, dynamic> json) {
    return OdooAckResult(
      success: json['success'] as bool? ?? true,
      processedCount: json['processed_count'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Sync state for user/device
class OdooSyncState {
  final int id;
  final int userId;
  final String deviceId;
  final String appType;
  final int lastEventId;
  final DateTime? lastSyncTime;
  final int syncCount;
  final int totalEventsSynced;
  final bool isActive;

  OdooSyncState({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.appType,
    required this.lastEventId,
    this.lastSyncTime,
    required this.syncCount,
    required this.totalEventsSynced,
    required this.isActive,
  });

  factory OdooSyncState.fromJson(Map<String, dynamic> json) {
    return OdooSyncState(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? '',
      appType: json['app_type'] as String? ?? 'mobile_app',
      lastEventId: json['last_event_id'] as int? ?? 0,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'] as String)
          : null,
      syncCount: json['sync_count'] as int? ?? 0,
      totalEventsSynced: json['total_events_synced'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'device_id': deviceId,
        'app_type': appType,
        'last_event_id': lastEventId,
        if (lastSyncTime != null)
          'last_sync_time': lastSyncTime!.toIso8601String(),
        'sync_count': syncCount,
        'total_events_synced': totalEventsSynced,
        'is_active': isActive,
      };
}

/// Sync statistics
class OdooSyncStatistics {
  final int? userId;
  final int totalDevices;
  final int activeDevices;
  final int totalSyncs;
  final int totalEventsSynced;
  final DateTime? lastSyncTime;
  final List<Map<String, dynamic>> devices;

  OdooSyncStatistics({
    this.userId,
    required this.totalDevices,
    required this.activeDevices,
    required this.totalSyncs,
    required this.totalEventsSynced,
    this.lastSyncTime,
    required this.devices,
  });

  factory OdooSyncStatistics.fromJson(Map<String, dynamic> json) {
    return OdooSyncStatistics(
      userId: json['user_id'] as int?,
      totalDevices: json['total_devices'] as int? ?? 0,
      activeDevices: json['active_devices'] as int? ?? 0,
      totalSyncs: json['total_syncs'] as int? ?? 0,
      totalEventsSynced: json['total_events_synced'] as int? ?? 0,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'] as String)
          : null,
      devices: (json['devices'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

/// Smart pull result
class OdooSmartPullResult {
  final bool success;
  final List<OdooEvent> events;
  final int count;
  final int lastId;
  final bool hasMore;
  final OdooSyncState? syncState;
  final String? error;

  OdooSmartPullResult({
    required this.success,
    required this.events,
    required this.count,
    required this.lastId,
    required this.hasMore,
    this.syncState,
    this.error,
  });

  factory OdooSmartPullResult.fromJson(Map<String, dynamic> json) {
    return OdooSmartPullResult(
      success: json['success'] as bool? ?? true,
      events: (json['events'] as List?)
              ?.map((e) => OdooEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] as int? ?? 0,
      lastId: json['last_id'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      syncState: json['sync_state'] != null
          ? OdooSyncState.fromJson(json['sync_state'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }
}

/// Health check result
class OdooSyncHealth {
  final String status;
  final bool odooConnected;
  final int pendingEvents;
  final DateTime? lastPullTime;
  final String? version;

  OdooSyncHealth({
    required this.status,
    required this.odooConnected,
    required this.pendingEvents,
    this.lastPullTime,
    this.version,
  });

  factory OdooSyncHealth.fromJson(Map<String, dynamic> json) {
    return OdooSyncHealth(
      status: json['status'] as String? ?? 'unknown',
      odooConnected: json['odoo_connected'] as bool? ?? false,
      pendingEvents: json['pending_events'] as int? ?? 0,
      lastPullTime: json['last_pull_time'] != null
          ? DateTime.parse(json['last_pull_time'] as String)
          : null,
      version: json['version'] as String?,
    );
  }

  bool get isHealthy => status == 'healthy' && odooConnected;
}

/// Full sync result
class OdooFullSyncResult {
  final bool success;
  final List<OdooEvent> events;
  final int totalSynced;
  final OdooSyncState? syncState;
  final String? error;

  OdooFullSyncResult({
    required this.success,
    required this.events,
    required this.totalSynced,
    this.syncState,
    this.error,
  });
}

