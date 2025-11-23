/// Response model for check_access_rights operation
class CheckAccessRightsResponse {
  /// Success status
  final bool success;

  /// Whether user has access
  final bool? hasAccess;

  /// Error message if operation failed
  final String? error;

  CheckAccessRightsResponse({
    required this.success,
    this.hasAccess,
    this.error,
  });

  factory CheckAccessRightsResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      return CheckAccessRightsResponse(
        success: true,
        hasAccess: json['result'] as bool,
      );
    }

    return CheckAccessRightsResponse(
      success: false,
      error: json['error'] as String? ?? 'Unknown error',
    );
  }
}

