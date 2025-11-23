/// Response model for fields_view_get operation
class FieldsViewGetResponse {
  /// Success status
  final bool success;

  /// View architecture (XML)
  final String? arch;

  /// View ID
  final int? viewId;

  /// Model name
  final String? model;

  /// Field definitions
  final Map<String, dynamic>? fields;

  /// Toolbar actions
  final Map<String, dynamic>? toolbar;

  /// Error message if operation failed
  final String? error;

  FieldsViewGetResponse({
    required this.success,
    this.arch,
    this.viewId,
    this.model,
    this.fields,
    this.toolbar,
    this.error,
  });

  factory FieldsViewGetResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;

    if (result == null) {
      return FieldsViewGetResponse(
        success: false,
        error: json['error'] as String? ?? 'Unknown error',
      );
    }

    return FieldsViewGetResponse(
      success: true,
      arch: result['arch'] as String?,
      viewId: result['view_id'] as int?,
      model: result['model'] as String?,
      fields: result['fields'] as Map<String, dynamic>?,
      toolbar: result['toolbar'] as Map<String, dynamic>?,
    );
  }
}

