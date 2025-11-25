/// Webhook Payload Model
///
/// Represents incoming webhook data from Odoo
class WebhookPayload {
  /// Webhook ID that triggered this payload
  final String webhookId;

  /// Model name
  final String model;

  /// Event type (create, write, unlink)
  final String event;

  /// Record ID
  final int recordId;

  /// Record data
  final Map<String, dynamic> data;

  /// Previous values (for write events)
  final Map<String, dynamic>? previousValues;

  /// Timestamp of the event
  final DateTime timestamp;

  /// User who triggered the event
  final int? userId;

  /// Company ID
  final int? companyId;

  WebhookPayload({
    required this.webhookId,
    required this.model,
    required this.event,
    required this.recordId,
    required this.data,
    this.previousValues,
    required this.timestamp,
    this.userId,
    this.companyId,
  });

  /// Create from JSON
  factory WebhookPayload.fromJson(Map<String, dynamic> json) {
    return WebhookPayload(
      webhookId: json['webhook_id'] as String,
      model: json['model'] as String,
      event: json['event'] as String,
      recordId: json['record_id'] as int,
      data: json['data'] as Map<String, dynamic>,
      previousValues: json['previous_values'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as int?,
      companyId: json['company_id'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'webhook_id': webhookId,
      'model': model,
      'event': event,
      'record_id': recordId,
      'data': data,
      if (previousValues != null) 'previous_values': previousValues,
      'timestamp': timestamp.toIso8601String(),
      if (userId != null) 'user_id': userId,
      if (companyId != null) 'company_id': companyId,
    };
  }

  /// Check if this is a create event
  bool get isCreate => event == 'create';

  /// Check if this is an update event
  bool get isUpdate => event == 'write';

  /// Check if this is a delete event
  bool get isDelete => event == 'unlink';

  /// Get changed fields (for write events)
  List<String> get changedFields {
    if (!isUpdate || previousValues == null) return [];
    return data.keys
        .where((key) => data[key] != previousValues![key])
        .toList();
  }

  /// Check if specific field was changed
  bool fieldChanged(String fieldName) {
    return changedFields.contains(fieldName);
  }

  @override
  String toString() {
    return 'WebhookPayload(model: $model, event: $event, recordId: $recordId)';
  }
}
