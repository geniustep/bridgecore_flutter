/// Response model for copy operation
class CopyResponse {
  /// Success status
  final bool success;

  /// ID of the new copied record
  final int? newId;

  /// Error message if operation failed
  final String? error;

  CopyResponse({
    required this.success,
    this.newId,
    this.error,
  });

  factory CopyResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      return CopyResponse(
        success: true,
        newId: json['result'] as int,
      );
    }

    return CopyResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

