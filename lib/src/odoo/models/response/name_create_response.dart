/// Response model for name_create operation
class NameCreateResponse {
  /// Success status
  final bool success;

  /// Created record [id, name]
  final List<dynamic>? record;

  /// Error message if operation failed
  final String? error;

  NameCreateResponse({
    required this.success,
    this.record,
    this.error,
  });

  factory NameCreateResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      return NameCreateResponse(
        success: true,
        record: json['result'] as List,
      );
    }

    return NameCreateResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }

  /// Get the ID of the created record
  int? get id => record?[0] as int?;

  /// Get the name of the created record
  String? get name => record?[1] as String?;
}

