/// Response model for read_group operation
class ReadGroupResponse {
  /// Success status
  final bool success;

  /// Grouped data
  final List<Map<String, dynamic>>? groups;

  /// Error message if operation failed
  final String? error;

  ReadGroupResponse({
    required this.success,
    this.groups,
    this.error,
  });

  factory ReadGroupResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      return ReadGroupResponse(
        success: true,
        groups: (json['result'] as List).cast<Map<String, dynamic>>(),
      );
    }

    return ReadGroupResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

