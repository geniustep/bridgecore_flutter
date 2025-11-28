import '../client/http_client.dart';
import '../core/endpoints.dart';
import 'models/trigger.dart';
import 'models/trigger_execution.dart';

/// Trigger service for automation management
///
/// Provides methods to manage automation triggers that respond to Odoo events.
///
/// Example:
/// ```dart
/// // Create a trigger
/// final trigger = await triggers.create(
///   name: 'Notify on New Order',
///   model: 'sale.order',
///   event: TriggerEvent.onCreate,
///   actionType: TriggerActionType.notification,
///   actionConfig: {
///     'title': 'New Order',
///     'message': 'Order {{record.name}} created',
///     'user_ids': [userId],
///   },
/// );
///
/// // List triggers
/// final triggers = await triggers.list();
///
/// // Execute manually
/// final result = await triggers.execute(triggerId);
/// ```
class TriggerService {
  final BridgeCoreHttpClient httpClient;

  TriggerService({required this.httpClient});

  /// Create a new trigger
  Future<Trigger> create({
    required String name,
    String? description,
    required String model,
    required TriggerEvent event,
    List<dynamic>? condition,
    required TriggerActionType actionType,
    required Map<String, dynamic> actionConfig,
    String? scheduleCron,
    String? scheduleTimezone,
    bool isEnabled = true,
    int priority = 10,
    int maxExecutionsPerHour = 100,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.triggerCreate,
      {
        'name': name,
        if (description != null) 'description': description,
        'model': model,
        'event': event.value,
        if (condition != null) 'condition': condition,
        'action_type': actionType.value,
        'action_config': actionConfig,
        if (scheduleCron != null) 'schedule_cron': scheduleCron,
        if (scheduleTimezone != null) 'schedule_timezone': scheduleTimezone,
        'is_enabled': isEnabled,
        'priority': priority,
        'max_executions_per_hour': maxExecutionsPerHour,
      },
    );

    return Trigger.fromJson(response);
  }

  /// List all triggers
  Future<TriggerListResponse> list({
    String? model,
    TriggerEvent? event,
    TriggerStatus? status,
    bool? isEnabled,
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      if (model != null) 'model': model,
      if (event != null) 'event': event.value,
      if (status != null) 'status': status.value,
      if (isEnabled != null) 'is_enabled': isEnabled,
      'skip': skip,
      'limit': limit,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await httpClient.get(
      '${BridgeCoreEndpoints.triggerList}?$queryString',
    );

    return TriggerListResponse.fromJson(response);
  }

  /// Get trigger by ID
  Future<Trigger> get(String triggerId) async {
    final response = await httpClient.get(
      '${BridgeCoreEndpoints.triggerGet}/$triggerId',
    );

    return Trigger.fromJson(response);
  }

  /// Update a trigger
  Future<Trigger> update(
    String triggerId, {
    String? name,
    String? description,
    String? model,
    TriggerEvent? event,
    List<dynamic>? condition,
    TriggerActionType? actionType,
    Map<String, dynamic>? actionConfig,
    String? scheduleCron,
    String? scheduleTimezone,
    bool? isEnabled,
    int? priority,
    int? maxExecutionsPerHour,
  }) async {
    final response = await httpClient.put(
      '${BridgeCoreEndpoints.triggerUpdate}/$triggerId',
      {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (model != null) 'model': model,
        if (event != null) 'event': event.value,
        if (condition != null) 'condition': condition,
        if (actionType != null) 'action_type': actionType.value,
        if (actionConfig != null) 'action_config': actionConfig,
        if (scheduleCron != null) 'schedule_cron': scheduleCron,
        if (scheduleTimezone != null) 'schedule_timezone': scheduleTimezone,
        if (isEnabled != null) 'is_enabled': isEnabled,
        if (priority != null) 'priority': priority,
        if (maxExecutionsPerHour != null)
          'max_executions_per_hour': maxExecutionsPerHour,
      },
    );

    return Trigger.fromJson(response);
  }

  /// Delete a trigger
  Future<bool> delete(String triggerId) async {
    final response = await httpClient.delete(
      '${BridgeCoreEndpoints.triggerDelete}/$triggerId',
    );

    return response['success'] ?? false;
  }

  /// Toggle trigger enabled status
  Future<Trigger> toggle(String triggerId, bool isEnabled) async {
    final response = await httpClient.post(
      '${BridgeCoreEndpoints.triggerToggle}/$triggerId/toggle',
      {'is_enabled': isEnabled},
    );

    return Trigger.fromJson(response);
  }

  /// Execute trigger manually
  Future<ManualExecutionResult> execute(
    String triggerId, {
    List<int>? recordIds,
    bool testMode = false,
  }) async {
    final response = await httpClient.post(
      '${BridgeCoreEndpoints.triggerExecute}/$triggerId/execute',
      {
        if (recordIds != null) 'record_ids': recordIds,
        'test_mode': testMode,
      },
    );

    return ManualExecutionResult.fromJson(response);
  }

  /// Get trigger execution history
  Future<TriggerExecutionListResponse> getHistory(
    String triggerId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await httpClient.get(
      '${BridgeCoreEndpoints.triggerHistory}/$triggerId/history?skip=$skip&limit=$limit',
    );

    return TriggerExecutionListResponse.fromJson(response);
  }

  /// Get trigger statistics
  Future<TriggerStats> getStats(String triggerId) async {
    final response = await httpClient.get(
      '${BridgeCoreEndpoints.triggerStats}/$triggerId/stats',
    );

    return TriggerStats.fromJson(response);
  }
}

