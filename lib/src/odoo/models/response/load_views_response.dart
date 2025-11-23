/// Response model for load_views operation
class LoadViewsResponse {
  /// Success status
  final bool success;

  /// Loaded views by type
  final Map<String, dynamic>? views;

  /// Fields information
  final Map<String, dynamic>? fields;

  /// Filters
  final List<dynamic>? filters;

  /// Error message if operation failed
  final String? error;

  LoadViewsResponse({
    required this.success,
    this.views,
    this.fields,
    this.filters,
    this.error,
  });

  factory LoadViewsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;

    if (result == null) {
      return LoadViewsResponse(
        success: false,
        error: json['error'] as String? ?? 'Unknown error',
      );
    }

    return LoadViewsResponse(
      success: true,
      views: result['views'] as Map<String, dynamic>?,
      fields: result['fields'] as Map<String, dynamic>?,
      filters: result['filters'] as List?,
    );
  }
}

