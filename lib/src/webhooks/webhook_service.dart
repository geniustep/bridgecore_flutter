import '../client/http_client.dart';
import '../core/endpoints.dart';
import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';
import 'models/webhook_registration.dart';
import 'models/webhook_payload.dart';
import 'models/webhook_delivery_log.dart';

/// Webhook Service
///
/// Manages webhook registration and handles incoming webhooks from Odoo
///
/// Usage:
/// ```dart
/// final webhooks = BridgeCore.instance.webhooks;
///
/// // Register webhook
/// final webhook = await webhooks.register(
///   model: 'sale.order',
///   event: 'create',
///   callbackUrl: 'https://myapp.com/webhooks/sale-order',
/// );
///
/// // Listen for webhook events
/// BridgeCoreEventBus.instance.on('webhook.received').listen((event) {
///   print('Webhook received: ${event.data}');
/// });
/// ```
class WebhookService {
  final BridgeCoreHttpClient httpClient;
  final BridgeCoreEventBus _eventBus = BridgeCoreEventBus.instance;

  /// Local cache of registered webhooks
  final Map<String, WebhookRegistration> _registeredWebhooks = {};

  WebhookService({required this.httpClient});

  // ════════════════════════════════════════════════════════════
  // Registration Methods
  // ════════════════════════════════════════════════════════════

  /// Register a new webhook
  ///
  /// Example:
  /// ```dart
  /// final webhook = await webhooks.register(
  ///   model: 'sale.order',
  ///   event: 'create',
  ///   callbackUrl: 'https://myapp.com/webhooks/sale-order',
  ///   filters: {'state': '=', 'draft'},
  /// );
  /// ```
  Future<WebhookRegistration> register({
    required String model,
    required String event,
    required String callbackUrl,
    Map<String, dynamic>? filters,
    Map<String, String>? headers,
    int? maxRetries,
    int? timeout,
  }) async {
    BridgeCoreLogger.info('Registering webhook for $model.$event');

    final response = await httpClient.post(
      BridgeCoreEndpoints.webhookRegister,
      {
        'model': model,
        'event': event,
        'callback_url': callbackUrl,
        if (filters != null) 'filters': filters,
        if (headers != null) 'headers': headers,
        if (maxRetries != null) 'max_retries': maxRetries,
        if (timeout != null) 'timeout': timeout,
      },
    );

    final webhook = WebhookRegistration.fromJson(response['webhook']);

    // Cache webhook
    _registeredWebhooks[webhook.id] = webhook;

    // Emit event
    _eventBus.emit(BridgeCoreEventTypes.webhookRegistered, {
      'webhook_id': webhook.id,
      'model': webhook.model,
      'event': webhook.event,
    });

    BridgeCoreLogger.info('Webhook registered: ${webhook.id}');

    return webhook;
  }

  /// Unregister a webhook
  ///
  /// Example:
  /// ```dart
  /// await webhooks.unregister('webhook_123');
  /// ```
  Future<bool> unregister(String webhookId) async {
    BridgeCoreLogger.info('Unregistering webhook: $webhookId');

    final response = await httpClient.delete(
      '${BridgeCoreEndpoints.webhookUnregister}/$webhookId',
    );

    // Remove from cache
    _registeredWebhooks.remove(webhookId);

    // Emit event
    _eventBus.emit(BridgeCoreEventTypes.webhookUnregistered, {
      'webhook_id': webhookId,
    });

    BridgeCoreLogger.info('Webhook unregistered: $webhookId');

    return response['success'] as bool? ?? true;
  }

  /// Update webhook configuration
  ///
  /// Example:
  /// ```dart
  /// await webhooks.update(
  ///   webhookId: 'webhook_123',
  ///   active: false,
  /// );
  /// ```
  Future<WebhookRegistration> update({
    required String webhookId,
    String? callbackUrl,
    Map<String, dynamic>? filters,
    bool? active,
    Map<String, String>? headers,
    int? maxRetries,
    int? timeout,
  }) async {
    BridgeCoreLogger.info('Updating webhook: $webhookId');

    final response = await httpClient.put(
      '${BridgeCoreEndpoints.webhookUpdate}/$webhookId',
      {
        if (callbackUrl != null) 'callback_url': callbackUrl,
        if (filters != null) 'filters': filters,
        if (active != null) 'active': active,
        if (headers != null) 'headers': headers,
        if (maxRetries != null) 'max_retries': maxRetries,
        if (timeout != null) 'timeout': timeout,
      },
    );

    final webhook = WebhookRegistration.fromJson(response['webhook']);

    // Update cache
    _registeredWebhooks[webhook.id] = webhook;

    BridgeCoreLogger.info('Webhook updated: $webhookId');

    return webhook;
  }

  // ════════════════════════════════════════════════════════════
  // Query Methods
  // ════════════════════════════════════════════════════════════

  /// List all registered webhooks
  ///
  /// Example:
  /// ```dart
  /// final webhooks = await webhooks.list();
  /// ```
  Future<List<WebhookRegistration>> list({
    String? model,
    String? event,
    bool? active,
  }) async {
    final queryParams = <String, String>{};
    if (model != null) queryParams['model'] = model;
    if (event != null) queryParams['event'] = event;
    if (active != null) queryParams['active'] = active.toString();

    final response = await httpClient.get(
      BridgeCoreEndpoints.webhookList,
      queryParams: queryParams,
    );

    final webhookList = (response['webhooks'] as List)
        .map((json) => WebhookRegistration.fromJson(json))
        .toList();

    // Update cache
    for (final webhook in webhookList) {
      _registeredWebhooks[webhook.id] = webhook;
    }

    return webhookList;
  }

  /// Get webhook details
  ///
  /// Example:
  /// ```dart
  /// final webhook = await webhooks.get('webhook_123');
  /// ```
  Future<WebhookRegistration> get(String webhookId) async {
    // Check cache first
    if (_registeredWebhooks.containsKey(webhookId)) {
      return _registeredWebhooks[webhookId]!;
    }

    final response = await httpClient.get(
      '${BridgeCoreEndpoints.webhookGet}/$webhookId',
    );

    final webhook = WebhookRegistration.fromJson(response['webhook']);

    // Update cache
    _registeredWebhooks[webhook.id] = webhook;

    return webhook;
  }

  /// Get webhook delivery logs
  ///
  /// Example:
  /// ```dart
  /// final logs = await webhooks.getLogs('webhook_123', limit: 50);
  /// ```
  Future<List<WebhookDeliveryLog>> getLogs(
    String webhookId, {
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final response = await httpClient.get(
      '${BridgeCoreEndpoints.webhookLogs}/$webhookId/logs',
      queryParams: queryParams,
    );

    return (response['logs'] as List)
        .map((json) => WebhookDeliveryLog.fromJson(json))
        .toList();
  }

  // ════════════════════════════════════════════════════════════
  // Testing Methods
  // ════════════════════════════════════════════════════════════

  /// Test webhook by triggering it manually
  ///
  /// Example:
  /// ```dart
  /// await webhooks.test('webhook_123');
  /// ```
  Future<WebhookDeliveryLog> test(String webhookId) async {
    BridgeCoreLogger.info('Testing webhook: $webhookId');

    final response = await httpClient.post(
      '${BridgeCoreEndpoints.webhookTest}/$webhookId/test',
      {},
    );

    return WebhookDeliveryLog.fromJson(response['delivery_log']);
  }

  // ════════════════════════════════════════════════════════════
  // Incoming Webhook Handling
  // ════════════════════════════════════════════════════════════

  /// Handle incoming webhook payload
  ///
  /// This should be called from your server endpoint that receives webhooks
  ///
  /// Example:
  /// ```dart
  /// // In your webhook endpoint handler
  /// webhooks.handleIncoming(request.body);
  /// ```
  void handleIncoming(Map<String, dynamic> payload) {
    try {
      final webhook = WebhookPayload.fromJson(payload);

      BridgeCoreLogger.info(
        'Webhook received: ${webhook.model}.${webhook.event} (ID: ${webhook.recordId})',
      );

      // Emit generic webhook event
      _eventBus.emit(BridgeCoreEventTypes.webhookReceived, {
        'webhook_id': webhook.webhookId,
        'model': webhook.model,
        'event': webhook.event,
        'record_id': webhook.recordId,
        'data': webhook.data,
      });

      // Emit specific Odoo events
      switch (webhook.event) {
        case 'create':
          _eventBus.emit(BridgeCoreEventTypes.odooRecordCreated, {
            'model': webhook.model,
            'id': webhook.recordId,
            'data': webhook.data,
          });
          break;

        case 'write':
          _eventBus.emit(BridgeCoreEventTypes.odooRecordUpdated, {
            'model': webhook.model,
            'id': webhook.recordId,
            'changes': webhook.data,
            'previous_values': webhook.previousValues,
            'changed_fields': webhook.changedFields,
          });
          break;

        case 'unlink':
          _eventBus.emit(BridgeCoreEventTypes.odooRecordDeleted, {
            'model': webhook.model,
            'id': webhook.recordId,
          });
          break;
      }
    } catch (e, stackTrace) {
      BridgeCoreLogger.error('Failed to handle webhook payload', null, e);
      _eventBus.emit(BridgeCoreEventTypes.webhookDeliveryFailed, {
        'error': e.toString(),
        'stack_trace': stackTrace.toString(),
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  // Convenience Methods
  // ════════════════════════════════════════════════════════════

  /// Register webhook for record creation
  Future<WebhookRegistration> onCreate({
    required String model,
    required String callbackUrl,
    Map<String, dynamic>? filters,
  }) {
    return register(
      model: model,
      event: WebhookEventType.create,
      callbackUrl: callbackUrl,
      filters: filters,
    );
  }

  /// Register webhook for record updates
  Future<WebhookRegistration> onUpdate({
    required String model,
    required String callbackUrl,
    Map<String, dynamic>? filters,
  }) {
    return register(
      model: model,
      event: WebhookEventType.write,
      callbackUrl: callbackUrl,
      filters: filters,
    );
  }

  /// Register webhook for record deletion
  Future<WebhookRegistration> onDelete({
    required String model,
    required String callbackUrl,
    Map<String, dynamic>? filters,
  }) {
    return register(
      model: model,
      event: WebhookEventType.unlink,
      callbackUrl: callbackUrl,
      filters: filters,
    );
  }

  /// Get cached webhooks (no API call)
  List<WebhookRegistration> getCachedWebhooks() {
    return _registeredWebhooks.values.toList();
  }

  /// Clear webhook cache
  void clearCache() {
    _registeredWebhooks.clear();
    BridgeCoreLogger.debug('Webhook cache cleared');
  }

  /// Get webhook statistics
  Map<String, dynamic> getStatistics() {
    final activeCount =
        _registeredWebhooks.values.where((w) => w.active).length;
    final inactiveCount =
        _registeredWebhooks.values.where((w) => !w.active).length;

    final byModel = <String, int>{};
    for (final webhook in _registeredWebhooks.values) {
      byModel[webhook.model] = (byModel[webhook.model] ?? 0) + 1;
    }

    final byEvent = <String, int>{};
    for (final webhook in _registeredWebhooks.values) {
      byEvent[webhook.event] = (byEvent[webhook.event] ?? 0) + 1;
    }

    return {
      'total': _registeredWebhooks.length,
      'active': activeCount,
      'inactive': inactiveCount,
      'by_model': byModel,
      'by_event': byEvent,
    };
  }
}
