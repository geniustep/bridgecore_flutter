import 'dart:async';
import 'package:dio/dio.dart';
import '../client/http_client.dart';
import '../core/endpoints.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';
import 'models/updates_info.dart';
import 'models/sync_status.dart';
import 'models/sync_history.dart';

/// Sync Service
///
/// Manages data synchronization and update checking
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
/// // Get detailed updates info
/// final updates = await sync.getUpdatesInfo();
/// print('${updates.updateCount} updates available');
///
/// // Start full sync
/// await sync.startSync();
/// ```
class SyncService {
  final BridgeCoreHttpClient httpClient;
  final BridgeCoreEventBus _eventBus = BridgeCoreEventBus.instance;

  /// Current sync status
  SyncStatus? _currentStatus;

  /// Periodic update checker timer
  Timer? _updateCheckTimer;

  /// Update check interval
  Duration _updateCheckInterval = const Duration(minutes: 5);

  SyncService({required this.httpClient});

  // ════════════════════════════════════════════════════════════
  // Update Check Methods
  // ════════════════════════════════════════════════════════════

  /// Check if updates are available (quick check)
  ///
  /// This is a lightweight endpoint that quickly checks if any updates exist
  ///
  /// Example:
  /// ```dart
  /// if (await sync.hasUpdates()) {
  ///   // Show update notification
  ///   showUpdateNotification();
  /// }
  /// ```
  Future<bool> hasUpdates() async {
    try {
      final response = await httpClient.get(
        BridgeCoreEndpoints.syncCheckUpdates,
      );

      final hasUpdate = response['has_updates'] as bool? ?? false;

      if (hasUpdate) {
        _eventBus.emit(BridgeCoreEventTypes.updatesAvailable, {
          'checked_at': DateTime.now().toIso8601String(),
        });

        BridgeCoreLogger.info('Updates available');
      }

      return hasUpdate;
    } on DioException catch (e) {
      _handleSyncError(e);
      return false;
    }
  }

  /// Get detailed updates information
  ///
  /// Returns comprehensive information about all available updates
  ///
  /// Example:
  /// ```dart
  /// final updates = await sync.getUpdatesInfo();
  /// print('Total updates: ${updates.updateCount}');
  ///
  /// for (var entry in updates.modelUpdates.entries) {
  ///   print('${entry.key}: ${entry.value.totalChanges} changes');
  /// }
  /// ```
  Future<UpdatesInfo> getUpdatesInfo() async {
    try {
      final response = await httpClient.get(
        BridgeCoreEndpoints.syncUpdatesInfo,
      );

      final updatesInfo = UpdatesInfo.fromJson(response);

      if (updatesInfo.hasUpdates) {
        _eventBus.emit(BridgeCoreEventTypes.updatesAvailable, {
          'update_count': updatesInfo.updateCount,
          'models': updatesInfo.modelUpdates.keys.toList(),
        });
      }

      return updatesInfo;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Check updates for specific model
  ///
  /// Example:
  /// ```dart
  /// final updates = await sync.checkModelUpdates(
  ///   model: 'sale.order',
  ///   lastSync: DateTime.now().subtract(Duration(hours: 1)),
  /// );
  ///
  /// if (updates.hasChanges) {
  ///   print('${updates.newRecords} new orders');
  ///   print('${updates.updatedRecords} updated orders');
  /// }
  /// ```
  Future<ModelUpdates> checkModelUpdates({
    required String model,
    DateTime? lastSync,
  }) async {
    try {
      final response = await httpClient.post(
        BridgeCoreEndpoints.syncCheckModelUpdates,
        {
          'model': model,
          if (lastSync != null) 'last_sync': lastSync.toIso8601String(),
        },
      );

      return ModelUpdates.fromJson(response['model_updates']);
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Sync Control Methods
  // ════════════════════════════════════════════════════════════

  /// Get current sync status
  ///
  /// Example:
  /// ```dart
  /// final status = await sync.getStatus();
  /// if (status.isRunning) {
  ///   print('Sync progress: ${status.progressPercentage}%');
  /// }
  /// ```
  Future<SyncStatus> getStatus() async {
    try {
      final response = await httpClient.get(
        BridgeCoreEndpoints.syncStatus,
      );

      _currentStatus = SyncStatus.fromJson(response['sync_status']);
      return _currentStatus!;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Start full synchronization
  ///
  /// Example:
  /// ```dart
  /// await sync.startSync(
  ///   models: ['sale.order', 'product.product'],
  ///   forceRefresh: true,
  /// );
  /// ```
  Future<SyncStatus> startSync({
    List<String>? models,
    bool forceRefresh = false,
  }) async {
    try {
      BridgeCoreLogger.info('Starting sync...');

      final response = await httpClient.post(
        BridgeCoreEndpoints.syncStart,
        {
          if (models != null) 'models': models,
          'force_refresh': forceRefresh,
        },
      );

      _currentStatus = SyncStatus.fromJson(response['sync_status']);

      _eventBus.emit(BridgeCoreEventTypes.syncStarted, {
        'models': models,
        'force_refresh': forceRefresh,
        'started_at': DateTime.now().toIso8601String(),
      });

      BridgeCoreLogger.info('Sync started');

      return _currentStatus!;
    } on DioException catch (e) {
      _eventBus.emit(BridgeCoreEventTypes.syncFailed, {
        'error': e.toString(),
      });
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Cancel ongoing synchronization
  ///
  /// Example:
  /// ```dart
  /// await sync.cancelSync();
  /// ```
  Future<bool> cancelSync() async {
    try {
      BridgeCoreLogger.info('Cancelling sync...');

      final response = await httpClient.post(
        BridgeCoreEndpoints.syncCancel,
        {},
      );

      _eventBus.emit(BridgeCoreEventTypes.syncCancelled, {
        'cancelled_at': DateTime.now().toIso8601String(),
      });

      BridgeCoreLogger.info('Sync cancelled');

      return response['success'] as bool? ?? true;
    } on DioException catch (e) {
      _handleSyncError(e);
      rethrow;
    }
  }

  /// Get sync history
  ///
  /// Example:
  /// ```dart
  /// final history = await sync.getHistory(limit: 10);
  /// for (var entry in history) {
  ///   print('Sync at ${entry.startedAt}: ${entry.status}');
  /// }
  /// ```
  Future<List<SyncHistoryEntry>> getHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final response = await httpClient.get(
        BridgeCoreEndpoints.syncHistory,
        queryParams: queryParams,
      );

      return (response['history'] as List)
          .map((json) => SyncHistoryEntry.fromJson(json))
          .toList();
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
  /// Automatically checks for updates at specified interval
  ///
  /// Example:
  /// ```dart
  /// sync.startPeriodicUpdateCheck(
  ///   interval: Duration(minutes: 5),
  /// );
  ///
  /// // Listen for updates
  /// BridgeCoreEventBus.instance.on('updates.available').listen((event) {
  ///   showUpdateNotification();
  /// });
  /// ```
  void startPeriodicUpdateCheck({Duration? interval}) {
    stopPeriodicUpdateCheck();

    if (interval != null) {
      _updateCheckInterval = interval;
    }

    BridgeCoreLogger.info(
      'Starting periodic update check (interval: ${_updateCheckInterval.inMinutes}m)',
    );

    _updateCheckTimer = Timer.periodic(_updateCheckInterval, (_) async {
      try {
        await hasUpdates();
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
  // Sync Monitoring
  // ════════════════════════════════════════════════════════════

  /// Monitor sync progress
  ///
  /// Continuously polls sync status and emits progress events
  ///
  /// Example:
  /// ```dart
  /// // Start monitoring
  /// sync.monitorSyncProgress();
  ///
  /// // Listen to progress
  /// BridgeCoreEventBus.instance.on('sync.progress').listen((event) {
  ///   print('Progress: ${event.data['progress']}%');
  /// });
  /// ```
  Future<void> monitorSyncProgress({
    Duration pollInterval = const Duration(seconds: 2),
    void Function(SyncStatus)? onProgress,
  }) async {
    while (true) {
      try {
        final status = await getStatus();

        if (!status.isRunning) {
          // Sync completed or not running
          if (_currentStatus?.isRunning == true) {
            // Was running, now stopped - emit completion event
            _eventBus.emit(BridgeCoreEventTypes.syncCompleted, {
              'completed_at': DateTime.now().toIso8601String(),
              'progress': status.progress,
            });
          }
          break;
        }

        // Emit progress event
        _eventBus.emit(BridgeCoreEventTypes.syncProgress, {
          'progress': status.progress,
          'progress_percentage': status.progressPercentage,
          'current_stage': status.currentStage,
          'synced_items': status.syncedItems,
          'total_items': status.totalItems,
        });

        // Call callback if provided
        onProgress?.call(status);

        _currentStatus = status;

        // Wait before next poll
        await Future.delayed(pollInterval);
      } catch (e) {
        BridgeCoreLogger.error('Error monitoring sync progress', null, e);
        break;
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // Utility Methods
  // ════════════════════════════════════════════════════════════

  /// Get current cached status (no API call)
  SyncStatus? get cachedStatus => _currentStatus;

  /// Check if sync is currently running (from cache)
  bool get isSyncRunning => _currentStatus?.isRunning ?? false;

  /// Dispose resources
  void dispose() {
    stopPeriodicUpdateCheck();
    _currentStatus = null;
  }

  // ════════════════════════════════════════════════════════════
  // Error Handling
  // ════════════════════════════════════════════════════════════

  void _handleSyncError(DioException error) {
    final message = error.response?.data?['message'] ?? error.message;

    BridgeCoreLogger.error('Sync error: $message', null, error);

    _eventBus.emit(BridgeCoreEventTypes.syncFailed, {
      'error': message,
      'status_code': error.response?.statusCode,
    });

    // Rethrow as appropriate BridgeCore exception
    if (error.response?.statusCode == 401) {
      throw UnauthorizedException(
        message ?? 'Unauthorized',
        statusCode: 401,
        endpoint: error.requestOptions.path,
        method: error.requestOptions.method,
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
