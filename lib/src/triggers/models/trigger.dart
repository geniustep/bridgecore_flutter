/// Trigger event types
enum TriggerEvent {
  onCreate('on_create'),
  onUpdate('on_update'),
  onDelete('on_delete'),
  onWorkflow('on_workflow'),
  scheduled('scheduled'),
  manual('manual');

  final String value;
  const TriggerEvent(this.value);

  static TriggerEvent fromString(String value) {
    return TriggerEvent.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerEvent.manual,
    );
  }
}

/// Trigger action types
enum TriggerActionType {
  webhook('webhook'),
  email('email'),
  notification('notification'),
  odooMethod('odoo_method'),
  customCode('custom_code');

  final String value;
  const TriggerActionType(this.value);

  static TriggerActionType fromString(String value) {
    return TriggerActionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerActionType.webhook,
    );
  }
}

/// Trigger status
enum TriggerStatus {
  active('active'),
  inactive('inactive'),
  error('error');

  final String value;
  const TriggerStatus(this.value);

  static TriggerStatus fromString(String value) {
    return TriggerStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerStatus.inactive,
    );
  }
}

/// Trigger model
class Trigger {
  final String id;
  final String name;
  final String? description;
  final String tenantId;
  final String model;
  final TriggerEvent event;
  final List<dynamic> condition;
  final TriggerActionType actionType;
  final Map<String, dynamic> actionConfig;
  final String? scheduleCron;
  final String scheduleTimezone;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final TriggerStatus status;
  final bool isEnabled;
  final int priority;
  final int executionCount;
  final int successCount;
  final int failureCount;
  final String? lastError;
  final DateTime? lastErrorAt;
  final int maxExecutionsPerHour;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trigger({
    required this.id,
    required this.name,
    this.description,
    required this.tenantId,
    required this.model,
    required this.event,
    required this.condition,
    required this.actionType,
    required this.actionConfig,
    this.scheduleCron,
    required this.scheduleTimezone,
    this.nextRunAt,
    this.lastRunAt,
    required this.status,
    required this.isEnabled,
    required this.priority,
    required this.executionCount,
    required this.successCount,
    required this.failureCount,
    this.lastError,
    this.lastErrorAt,
    required this.maxExecutionsPerHour,
    required this.createdAt,
    this.updatedAt,
  });

  factory Trigger.fromJson(Map<String, dynamic> json) {
    return Trigger(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      tenantId: json['tenant_id'],
      model: json['model'],
      event: TriggerEvent.fromString(json['event']),
      condition: json['condition'] ?? [],
      actionType: TriggerActionType.fromString(json['action_type']),
      actionConfig: json['action_config'] ?? {},
      scheduleCron: json['schedule_cron'],
      scheduleTimezone: json['schedule_timezone'] ?? 'UTC',
      nextRunAt: json['next_run_at'] != null
          ? DateTime.parse(json['next_run_at'])
          : null,
      lastRunAt: json['last_run_at'] != null
          ? DateTime.parse(json['last_run_at'])
          : null,
      status: TriggerStatus.fromString(json['status']),
      isEnabled: json['is_enabled'] ?? true,
      priority: json['priority'] ?? 10,
      executionCount: json['execution_count'] ?? 0,
      successCount: json['success_count'] ?? 0,
      failureCount: json['failure_count'] ?? 0,
      lastError: json['last_error'],
      lastErrorAt: json['last_error_at'] != null
          ? DateTime.parse(json['last_error_at'])
          : null,
      maxExecutionsPerHour: json['max_executions_per_hour'] ?? 100,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tenant_id': tenantId,
      'model': model,
      'event': event.value,
      'condition': condition,
      'action_type': actionType.value,
      'action_config': actionConfig,
      'schedule_cron': scheduleCron,
      'schedule_timezone': scheduleTimezone,
      'next_run_at': nextRunAt?.toIso8601String(),
      'last_run_at': lastRunAt?.toIso8601String(),
      'status': status.value,
      'is_enabled': isEnabled,
      'priority': priority,
      'execution_count': executionCount,
      'success_count': successCount,
      'failure_count': failureCount,
      'last_error': lastError,
      'last_error_at': lastErrorAt?.toIso8601String(),
      'max_executions_per_hour': maxExecutionsPerHour,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Calculate success rate
  double get successRate {
    if (executionCount == 0) return 0;
    return (successCount / executionCount) * 100;
  }
}

/// Trigger list response
class TriggerListResponse {
  final List<Trigger> triggers;
  final int total;
  final int skip;
  final int limit;

  TriggerListResponse({
    required this.triggers,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory TriggerListResponse.fromJson(Map<String, dynamic> json) {
    return TriggerListResponse(
      triggers: (json['triggers'] as List)
          .map((e) => Trigger.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 100,
    );
  }
}

/// Trigger statistics
class TriggerStats {
  final String triggerId;
  final String name;
  final int totalExecutions;
  final int successfulExecutions;
  final int failedExecutions;
  final double successRate;
  final double? avgDurationMs;
  final DateTime? lastExecution;
  final int executionsToday;
  final int executionsThisWeek;

  TriggerStats({
    required this.triggerId,
    required this.name,
    required this.totalExecutions,
    required this.successfulExecutions,
    required this.failedExecutions,
    required this.successRate,
    this.avgDurationMs,
    this.lastExecution,
    required this.executionsToday,
    required this.executionsThisWeek,
  });

  factory TriggerStats.fromJson(Map<String, dynamic> json) {
    return TriggerStats(
      triggerId: json['trigger_id'],
      name: json['name'],
      totalExecutions: json['total_executions'] ?? 0,
      successfulExecutions: json['successful_executions'] ?? 0,
      failedExecutions: json['failed_executions'] ?? 0,
      successRate: (json['success_rate'] ?? 0).toDouble(),
      avgDurationMs: json['avg_duration_ms']?.toDouble(),
      lastExecution: json['last_execution'] != null
          ? DateTime.parse(json['last_execution'])
          : null,
      executionsToday: json['executions_today'] ?? 0,
      executionsThisWeek: json['executions_this_week'] ?? 0,
    );
  }
}

