/// Webhook Registration Model
///
/// Represents a registered webhook in the system
class WebhookRegistration {
  /// Unique webhook ID
  final String id;

  /// Model to monitor (e.g., 'sale.order')
  final String model;

  /// Event type (create, write, unlink)
  final String event;

  /// Callback URL where webhook will be delivered
  final String callbackUrl;

  /// Optional filters for the webhook
  final Map<String, dynamic>? filters;

  /// Whether webhook is active
  final bool active;

  /// When webhook was created
  final DateTime createdAt;

  /// When webhook was last updated
  final DateTime? updatedAt;

  /// Webhook secret for signature verification
  final String? secret;

  /// Custom headers to include in webhook delivery
  final Map<String, String>? headers;

  /// Maximum retry attempts on delivery failure
  final int? maxRetries;

  /// Timeout for webhook delivery (in seconds)
  final int? timeout;

  WebhookRegistration({
    required this.id,
    required this.model,
    required this.event,
    required this.callbackUrl,
    this.filters,
    this.active = true,
    required this.createdAt,
    this.updatedAt,
    this.secret,
    this.headers,
    this.maxRetries,
    this.timeout,
  });

  /// Create from JSON
  factory WebhookRegistration.fromJson(Map<String, dynamic> json) {
    return WebhookRegistration(
      id: json['id'] as String,
      model: json['model'] as String,
      event: json['event'] as String,
      callbackUrl: json['callback_url'] as String,
      filters: json['filters'] as Map<String, dynamic>?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      secret: json['secret'] as String?,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'] as Map)
          : null,
      maxRetries: json['max_retries'] as int?,
      timeout: json['timeout'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'event': event,
      'callback_url': callbackUrl,
      if (filters != null) 'filters': filters,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (secret != null) 'secret': secret,
      if (headers != null) 'headers': headers,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (timeout != null) 'timeout': timeout,
    };
  }

  /// Copy with modifications
  WebhookRegistration copyWith({
    String? id,
    String? model,
    String? event,
    String? callbackUrl,
    Map<String, dynamic>? filters,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? secret,
    Map<String, String>? headers,
    int? maxRetries,
    int? timeout,
  }) {
    return WebhookRegistration(
      id: id ?? this.id,
      model: model ?? this.model,
      event: event ?? this.event,
      callbackUrl: callbackUrl ?? this.callbackUrl,
      filters: filters ?? this.filters,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      secret: secret ?? this.secret,
      headers: headers ?? this.headers,
      maxRetries: maxRetries ?? this.maxRetries,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  String toString() {
    return 'WebhookRegistration(id: $id, model: $model, event: $event, active: $active)';
  }
}

/// Webhook Event Types
class WebhookEventType {
  static const String create = 'create';
  static const String write = 'write';
  static const String unlink = 'unlink';

  static const List<String> all = [create, write, unlink];

  static bool isValid(String event) {
    return all.contains(event);
  }
}
