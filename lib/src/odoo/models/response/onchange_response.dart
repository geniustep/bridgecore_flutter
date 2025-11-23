/// Response model for onchange operation
class OnchangeResponse {
  /// Success status
  final bool success;

  /// Updated field values after onchange
  final Map<String, dynamic>? value;

  /// Warnings to display to user
  final List<OnchangeWarning>? warnings;

  /// Domain changes for fields
  final Map<String, dynamic>? domain;

  /// Error message if operation failed
  final String? error;

  OnchangeResponse({
    required this.success,
    this.value,
    this.warnings,
    this.domain,
    this.error,
  });

  factory OnchangeResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;

    if (result == null) {
      return OnchangeResponse(
        success: false,
        error: json['error'] as String? ?? 'Unknown error',
      );
    }

    return OnchangeResponse(
      success: true,
      value: result['value'] as Map<String, dynamic>?,
      warnings: (result['warning'] as Map<String, dynamic>?)?.entries
          .map((e) => OnchangeWarning(
                title: e.key,
                message: e.value.toString(),
              ))
          .toList(),
      domain: result['domain'] as Map<String, dynamic>?,
    );
  }
}

/// Warning from onchange operation
class OnchangeWarning {
  final String title;
  final String message;

  OnchangeWarning({
    required this.title,
    required this.message,
  });
}

