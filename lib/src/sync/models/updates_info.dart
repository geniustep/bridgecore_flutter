/// Updates Information Model
///
/// Contains detailed information about available updates
class UpdatesInfo {
  /// Whether updates are available
  final bool hasUpdates;

  /// Number of updates available
  final int updateCount;

  /// Updates by model
  final Map<String, ModelUpdates> modelUpdates;

  /// Last sync timestamp
  final DateTime? lastSync;

  /// Server timestamp
  final DateTime serverTime;

  UpdatesInfo({
    required this.hasUpdates,
    required this.updateCount,
    required this.modelUpdates,
    this.lastSync,
    required this.serverTime,
  });

  /// Create from JSON
  factory UpdatesInfo.fromJson(Map<String, dynamic> json) {
    final modelUpdatesMap = <String, ModelUpdates>{};
    if (json['model_updates'] != null) {
      final updates = json['model_updates'] as Map<String, dynamic>;
      updates.forEach((model, data) {
        modelUpdatesMap[model] = ModelUpdates.fromJson(data);
      });
    }

    return UpdatesInfo(
      hasUpdates: json['has_updates'] as bool,
      updateCount: json['update_count'] as int,
      modelUpdates: modelUpdatesMap,
      lastSync: json['last_sync'] != null
          ? DateTime.parse(json['last_sync'] as String)
          : null,
      serverTime: DateTime.parse(json['server_time'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'has_updates': hasUpdates,
      'update_count': updateCount,
      'model_updates': modelUpdates.map((k, v) => MapEntry(k, v.toJson())),
      if (lastSync != null) 'last_sync': lastSync!.toIso8601String(),
      'server_time': serverTime.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UpdatesInfo(hasUpdates: $hasUpdates, count: $updateCount)';
  }
}

/// Model-specific updates information
class ModelUpdates {
  /// Model name
  final String model;

  /// Number of new records
  final int newRecords;

  /// Number of updated records
  final int updatedRecords;

  /// Number of deleted records
  final int deletedRecords;

  /// IDs of new records
  final List<int> newIds;

  /// IDs of updated records
  final List<int> updatedIds;

  /// IDs of deleted records
  final List<int> deletedIds;

  /// Last update timestamp for this model
  final DateTime? lastUpdate;

  ModelUpdates({
    required this.model,
    required this.newRecords,
    required this.updatedRecords,
    required this.deletedRecords,
    required this.newIds,
    required this.updatedIds,
    required this.deletedIds,
    this.lastUpdate,
  });

  /// Create from JSON
  factory ModelUpdates.fromJson(Map<String, dynamic> json) {
    return ModelUpdates(
      model: json['model'] as String,
      newRecords: json['new_records'] as int? ?? 0,
      updatedRecords: json['updated_records'] as int? ?? 0,
      deletedRecords: json['deleted_records'] as int? ?? 0,
      newIds: (json['new_ids'] as List?)?.cast<int>() ?? [],
      updatedIds: (json['updated_ids'] as List?)?.cast<int>() ?? [],
      deletedIds: (json['deleted_ids'] as List?)?.cast<int>() ?? [],
      lastUpdate: json['last_update'] != null
          ? DateTime.parse(json['last_update'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'new_records': newRecords,
      'updated_records': updatedRecords,
      'deleted_records': deletedRecords,
      'new_ids': newIds,
      'updated_ids': updatedIds,
      'deleted_ids': deletedIds,
      if (lastUpdate != null) 'last_update': lastUpdate!.toIso8601String(),
    };
  }

  /// Total number of changes
  int get totalChanges => newRecords + updatedRecords + deletedRecords;

  /// Check if there are any changes
  bool get hasChanges => totalChanges > 0;

  @override
  String toString() {
    return 'ModelUpdates(model: $model, new: $newRecords, updated: $updatedRecords, deleted: $deletedRecords)';
  }
}
