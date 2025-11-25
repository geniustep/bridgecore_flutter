/// Webhook Delivery Log
///
/// Represents a log entry for webhook delivery attempt
class WebhookDeliveryLog {
  /// Log entry ID
  final String id;

  /// Webhook ID
  final String webhookId;

  /// Delivery status
  final WebhookDeliveryStatus status;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Response body (if applicable)
  final String? responseBody;

  /// Error message (if failed)
  final String? errorMessage;

  /// Attempt number
  final int attemptNumber;

  /// Maximum attempts
  final int maxAttempts;

  /// When delivery was attempted
  final DateTime attemptedAt;

  /// How long the delivery took (in milliseconds)
  final int? durationMs;

  /// Payload that was sent
  final Map<String, dynamic>? payload;

  /// Next retry time (if scheduled)
  final DateTime? nextRetryAt;

  WebhookDeliveryLog({
    required this.id,
    required this.webhookId,
    required this.status,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    required this.attemptNumber,
    required this.maxAttempts,
    required this.attemptedAt,
    this.durationMs,
    this.payload,
    this.nextRetryAt,
  });

  /// Create from JSON
  factory WebhookDeliveryLog.fromJson(Map<String, dynamic> json) {
    return WebhookDeliveryLog(
      id: json['id'] as String,
      webhookId: json['webhook_id'] as String,
      status: WebhookDeliveryStatus.fromString(json['status'] as String),
      statusCode: json['status_code'] as int?,
      responseBody: json['response_body'] as String?,
      errorMessage: json['error_message'] as String?,
      attemptNumber: json['attempt_number'] as int,
      maxAttempts: json['max_attempts'] as int,
      attemptedAt: DateTime.parse(json['attempted_at'] as String),
      durationMs: json['duration_ms'] as int?,
      payload: json['payload'] as Map<String, dynamic>?,
      nextRetryAt: json['next_retry_at'] != null
          ? DateTime.parse(json['next_retry_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'webhook_id': webhookId,
      'status': status.toString(),
      if (statusCode != null) 'status_code': statusCode,
      if (responseBody != null) 'response_body': responseBody,
      if (errorMessage != null) 'error_message': errorMessage,
      'attempt_number': attemptNumber,
      'max_attempts': maxAttempts,
      'attempted_at': attemptedAt.toIso8601String(),
      if (durationMs != null) 'duration_ms': durationMs,
      if (payload != null) 'payload': payload,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt!.toIso8601String(),
    };
  }

  /// Check if delivery succeeded
  bool get isSuccess => status == WebhookDeliveryStatus.success;

  /// Check if delivery failed
  bool get isFailed => status == WebhookDeliveryStatus.failed;

  /// Check if delivery is pending retry
  bool get isPendingRetry => status == WebhookDeliveryStatus.pendingRetry;

  /// Check if all retries exhausted
  bool get isExhausted => attemptNumber >= maxAttempts;

  @override
  String toString() {
    return 'WebhookDeliveryLog(id: $id, status: $status, attempt: $attemptNumber/$maxAttempts)';
  }
}

/// Webhook Delivery Status
enum WebhookDeliveryStatus {
  success,
  failed,
  pendingRetry,
  cancelled;

  @override
  String toString() {
    switch (this) {
      case WebhookDeliveryStatus.success:
        return 'success';
      case WebhookDeliveryStatus.failed:
        return 'failed';
      case WebhookDeliveryStatus.pendingRetry:
        return 'pending_retry';
      case WebhookDeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  static WebhookDeliveryStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return WebhookDeliveryStatus.success;
      case 'failed':
        return WebhookDeliveryStatus.failed;
      case 'pending_retry':
        return WebhookDeliveryStatus.pendingRetry;
      case 'cancelled':
        return WebhookDeliveryStatus.cancelled;
      default:
        throw ArgumentError('Invalid webhook delivery status: $status');
    }
  }
}
