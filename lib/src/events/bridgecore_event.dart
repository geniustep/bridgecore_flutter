/// BridgeCore Event Model
///
/// Represents an event that occurred in the system
class BridgeCoreEvent {
  /// Event type (e.g., 'auth.login', 'odoo.record_created')
  final String type;

  /// Event data payload
  final Map<String, dynamic> data;

  /// Timestamp when event was created
  final DateTime timestamp;

  /// Event source (optional)
  final String? source;

  /// Event ID (optional, for tracking)
  final String? id;

  BridgeCoreEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.source,
    this.id,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create event from JSON
  factory BridgeCoreEvent.fromJson(Map<String, dynamic> json) {
    return BridgeCoreEvent(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      source: json['source'] as String?,
      id: json['id'] as String?,
    );
  }

  /// Convert event to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      if (source != null) 'source': source,
      if (id != null) 'id': id,
    };
  }

  @override
  String toString() {
    return 'BridgeCoreEvent(type: $type, timestamp: $timestamp, data: $data)';
  }

  /// Check if event is of specific type
  bool isType(String eventType) {
    return type == eventType;
  }

  /// Check if event matches any of the given types
  bool isAnyType(List<String> eventTypes) {
    return eventTypes.contains(type);
  }

  /// Check if event has specific data key
  bool hasData(String key) {
    return data.containsKey(key);
  }

  /// Get data value by key with type casting
  T? getData<T>(String key) {
    return data[key] as T?;
  }

  /// Get data value with default
  T getDataOrDefault<T>(String key, T defaultValue) {
    return (data[key] as T?) ?? defaultValue;
  }
}
