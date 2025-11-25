/// Sync History Entry
///
/// Represents a completed sync operation
class SyncHistoryEntry {
  /// Entry ID
  final String id;

  /// When sync started
  final DateTime startedAt;

  /// When sync completed
  final DateTime completedAt;

  /// Sync status
  final SyncHistoryStatus status;

  /// Number of records synced
  final int recordsSynced;

  /// Number of errors encountered
  final int errorCount;

  /// Sync duration in seconds
  final int durationSeconds;

  /// Error details (if any)
  final List<String>? errors;

  /// Models that were synced
  final List<String>? models;

  /// Sync statistics
  final Map<String, dynamic>? statistics;

  SyncHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.status,
    required this.recordsSynced,
    required this.errorCount,
    required this.durationSeconds,
    this.errors,
    this.models,
    this.statistics,
  });

  /// Create from JSON
  factory SyncHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SyncHistoryEntry(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
      status: SyncHistoryStatus.fromString(json['status'] as String),
      recordsSynced: json['records_synced'] as int,
      errorCount: json['error_count'] as int,
      durationSeconds: json['duration_seconds'] as int,
      errors: (json['errors'] as List?)?.cast<String>(),
      models: (json['models'] as List?)?.cast<String>(),
      statistics: json['statistics'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'status': status.toString(),
      'records_synced': recordsSynced,
      'error_count': errorCount,
      'duration_seconds': durationSeconds,
      if (errors != null) 'errors': errors,
      if (models != null) 'models': models,
      if (statistics != null) 'statistics': statistics,
    };
  }

  /// Get sync duration
  Duration get duration => Duration(seconds: durationSeconds);

  /// Check if sync was successful
  bool get isSuccess => status == SyncHistoryStatus.success;

  /// Check if sync failed
  bool get isFailed => status == SyncHistoryStatus.failed;

  /// Check if sync was cancelled
  bool get isCancelled => status == SyncHistoryStatus.cancelled;

  @override
  String toString() {
    return 'SyncHistoryEntry(id: $id, status: $status, records: $recordsSynced)';
  }
}

/// Sync History Status
enum SyncHistoryStatus {
  success,
  failed,
  cancelled,
  partial;

  @override
  String toString() {
    switch (this) {
      case SyncHistoryStatus.success:
        return 'success';
      case SyncHistoryStatus.failed:
        return 'failed';
      case SyncHistoryStatus.cancelled:
        return 'cancelled';
      case SyncHistoryStatus.partial:
        return 'partial';
    }
  }

  static SyncHistoryStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return SyncHistoryStatus.success;
      case 'failed':
        return SyncHistoryStatus.failed;
      case 'cancelled':
        return SyncHistoryStatus.cancelled;
      case 'partial':
        return SyncHistoryStatus.partial;
      default:
        throw ArgumentError('Invalid sync history status: $status');
    }
  }
}
