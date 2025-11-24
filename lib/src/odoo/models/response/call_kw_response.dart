/// Response model for call_kw operation
class CallKwResponse {
  /// Success status
  final bool success;

  /// Method result (can be any type)
  final dynamic result;

  /// Error message if operation failed
  final String? error;

  /// Action dictionary if method returns a window action (Odoo 18)
  final Map<String, dynamic>? action;

  /// Warnings from Odoo
  final List<dynamic>? warnings;

  /// Error details from Odoo 18
  final Map<String, dynamic>? errorDetails;

  CallKwResponse({
    required this.success,
    this.result,
    this.error,
    this.action,
    this.warnings,
    this.errorDetails,
  });

  /// Check if result is a window action
  bool get isAction => action != null;

  /// Check if there are warnings
  bool get hasWarnings => warnings != null && warnings!.isNotEmpty;

  factory CallKwResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('result')) {
      final result = json['result'];

      // Check if result is an action dictionary
      Map<String, dynamic>? actionDict;
      if (result is Map<String, dynamic> && result.containsKey('type')) {
        actionDict = result;
      }

      return CallKwResponse(
        success: true,
        result: result,
        action: actionDict,
        warnings: json['warnings'] as List<dynamic>?,
      );
    }

    // Handle error response
    final errorData = json['error'];
    String? errorMessage;
    Map<String, dynamic>? errorDetailsMap;

    if (errorData is String) {
      errorMessage = errorData;
    } else if (errorData is Map<String, dynamic>) {
      errorMessage = errorData['message'] as String? ??
          errorData['data']?['message'] as String? ??
          'Unknown error';
      errorDetailsMap = errorData;
    }

    return CallKwResponse(
      success: false,
      error: errorMessage ?? 'Unknown error',
      errorDetails: errorDetailsMap,
    );
  }
}
