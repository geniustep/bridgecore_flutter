/// Request model for call_kw operation
///
/// Generic Odoo RPC caller compatible with execute_kw
/// This is the most compatible way to call any Odoo method
///
/// Example:
/// ```dart
/// CallKwRequest(
///   model: 'res.partner',
///   method: 'search_read',
///   args: [[['is_company', '=', true]]],
///   kwargs: {'fields': ['name', 'email'], 'limit': 10},
///   context: {'lang': 'ar_001'},
/// );
/// ```
class CallKwRequest {
  /// Model name
  final String model;

  /// Method name to call
  final String method;

  /// Positional arguments (list)
  final List<dynamic> args;

  /// Keyword arguments
  final Map<String, dynamic> kwargs;

  /// Context for Odoo 18
  final Map<String, dynamic>? context;

  CallKwRequest({
    required this.model,
    required this.method,
    this.args = const [],
    this.kwargs = const {},
    this.context,
  });

  Map<String, dynamic> toJson() {
    // Merge context into kwargs if provided
    final finalKwargs = <String, dynamic>{
      ...kwargs,
      if (context != null) 'context': context,
    };

    return {
      'model': model,
      'method': method,
      'args': args,
      'kwargs': finalKwargs,
    };
  }
}
