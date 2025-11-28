/// Trigger execution record
class TriggerExecution {
  final String id;
  final String triggerId;
  final String tenantId;
  final int? recordId;
  final Map<String, dynamic>? recordData;
  final bool success;
  final Map<String, dynamic>? result;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMs;
  final DateTime createdAt;

  TriggerExecution({
    required this.id,
    required this.triggerId,
    required this.tenantId,
    this.recordId,
    this.recordData,
    required this.success,
    this.result,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
    this.durationMs,
    required this.createdAt,
  });

  factory TriggerExecution.fromJson(Map<String, dynamic> json) {
    return TriggerExecution(
      id: json['id'],
      triggerId: json['trigger_id'],
      tenantId: json['tenant_id'],
      recordId: json['record_id'],
      recordData: json['record_data'],
      success: json['success'] ?? false,
      result: json['result'],
      errorMessage: json['error_message'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationMs: json['duration_ms'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trigger_id': triggerId,
      'tenant_id': tenantId,
      'record_id': recordId,
      'record_data': recordData,
      'success': success,
      'result': result,
      'error_message': errorMessage,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration_ms': durationMs,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Trigger execution list response
class TriggerExecutionListResponse {
  final List<TriggerExecution> executions;
  final int total;
  final int skip;
  final int limit;

  TriggerExecutionListResponse({
    required this.executions,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory TriggerExecutionListResponse.fromJson(Map<String, dynamic> json) {
    return TriggerExecutionListResponse(
      executions: (json['executions'] as List)
          .map((e) => TriggerExecution.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 50,
    );
  }
}

/// Manual execution result
class ManualExecutionResult {
  final bool success;
  final String message;
  final int executedCount;
  final List<Map<String, dynamic>> results;

  ManualExecutionResult({
    required this.success,
    required this.message,
    required this.executedCount,
    required this.results,
  });

  factory ManualExecutionResult.fromJson(Map<String, dynamic> json) {
    return ManualExecutionResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      executedCount: json['executed_count'] ?? 0,
      results: (json['results'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
    );
  }
}

