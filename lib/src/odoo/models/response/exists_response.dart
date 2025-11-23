/// Response model for exists operation
class ExistsResponse {
  /// Success status
  final bool success;

  /// IDs that exist
  final List<int>? existingIds;

  /// Error message if operation failed
  final String? error;

  ExistsResponse({
    required this.success,
    this.existingIds,
    this.error,
  });

  factory ExistsResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      return ExistsResponse(
        success: true,
        existingIds: (json['result'] as List).cast<int>(),
      );
    }

    return ExistsResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

