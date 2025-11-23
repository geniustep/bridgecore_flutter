/// Response model for call_method operation
class CallMethodResponse {
  /// Success status
  final bool success;

  /// Method result (can be any type)
  final dynamic result;

  /// Error message if operation failed
  final String? error;

  CallMethodResponse({
    required this.success,
    this.result,
    this.error,
  });

  factory CallMethodResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('result')) {
      return CallMethodResponse(
        success: true,
        result: json['result'],
      );
    }

    return CallMethodResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

