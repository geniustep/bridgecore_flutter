/// Response model for get_views operation (Odoo 16+)
class GetViewsResponse {
  /// Success status
  final bool success;

  /// Loaded views by type
  final Map<String, dynamic>? views;

  /// Models information
  final Map<String, dynamic>? models;

  /// Error message if operation failed
  final String? error;

  GetViewsResponse({
    required this.success,
    this.views,
    this.models,
    this.error,
  });

  factory GetViewsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;

    if (result == null) {
      return GetViewsResponse(
        success: false,
        error: json['error'] as String? ?? 'Unknown error',
      );
    }

    return GetViewsResponse(
      success: true,
      views: result['views'] as Map<String, dynamic>?,
      models: result['models'] as Map<String, dynamic>?,
    );
  }
}

