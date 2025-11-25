/// Sync Status Model
///
/// Represents the current sync status
class SyncStatus {
  /// Whether sync is currently running
  final bool isRunning;

  /// Current sync progress (0.0 to 1.0)
  final double progress;

  /// Current sync stage
  final String? currentStage;

  /// Total items to sync
  final int? totalItems;

  /// Items synced so far
  final int? syncedItems;

  /// When sync started
  final DateTime? startedAt;

  /// Estimated completion time
  final DateTime? estimatedCompletion;

  /// Sync errors (if any)
  final List<String>? errors;

  /// Last successful sync
  final DateTime? lastSuccessfulSync;

  SyncStatus({
    required this.isRunning,
    required this.progress,
    this.currentStage,
    this.totalItems,
    this.syncedItems,
    this.startedAt,
    this.estimatedCompletion,
    this.errors,
    this.lastSuccessfulSync,
  });

  /// Create from JSON
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      isRunning: json['is_running'] as bool,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentStage: json['current_stage'] as String?,
      totalItems: json['total_items'] as int?,
      syncedItems: json['synced_items'] as int?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.parse(json['estimated_completion'] as String)
          : null,
      errors: (json['errors'] as List?)?.cast<String>(),
      lastSuccessfulSync: json['last_successful_sync'] != null
          ? DateTime.parse(json['last_successful_sync'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'is_running': isRunning,
      'progress': progress,
      if (currentStage != null) 'current_stage': currentStage,
      if (totalItems != null) 'total_items': totalItems,
      if (syncedItems != null) 'synced_items': syncedItems,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (estimatedCompletion != null)
        'estimated_completion': estimatedCompletion!.toIso8601String(),
      if (errors != null) 'errors': errors,
      if (lastSuccessfulSync != null)
        'last_successful_sync': lastSuccessfulSync!.toIso8601String(),
    };
  }

  /// Get progress percentage
  int get progressPercentage => (progress * 100).round();

  /// Check if sync has errors
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Get sync duration
  Duration? get duration {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!);
  }

  /// Get remaining time estimate
  Duration? get remainingTime {
    if (estimatedCompletion == null) return null;
    final now = DateTime.now();
    if (estimatedCompletion!.isBefore(now)) return Duration.zero;
    return estimatedCompletion!.difference(now);
  }

  @override
  String toString() {
    return 'SyncStatus(running: $isRunning, progress: ${progressPercentage}%, stage: $currentStage)';
  }
}
