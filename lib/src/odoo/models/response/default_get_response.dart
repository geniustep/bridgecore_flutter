/// Response model for default_get operation
class DefaultGetResponse {
  /// Success status
  final bool success;

  /// Default field values
  final Map<String, dynamic>? defaults;

  /// Error message if operation failed
  final String? error;

  DefaultGetResponse({
    required this.success,
    this.defaults,
    this.error,
  });

  factory DefaultGetResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      return DefaultGetResponse(
        success: true,
        defaults: json['result'] as Map<String, dynamic>,
      );
    }

    return DefaultGetResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

