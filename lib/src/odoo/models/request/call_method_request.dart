/// Request model for call_method operation
///
/// Generic method caller for any Odoo model method
class CallMethodRequest {
  /// Model name
  final String model;

  /// Method name to call
  final String method;

  /// Record IDs (if method operates on records)
  final List<int>? ids;

  /// Positional arguments
  final List<dynamic>? args;

  /// Keyword arguments
  final Map<String, dynamic>? kwargs;

  CallMethodRequest({
    required this.model,
    required this.method,
    this.ids,
    this.args,
    this.kwargs,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'method': method,
        if (ids != null) 'ids': ids,
        if (args != null) 'args': args,
        if (kwargs != null) 'kwargs': kwargs,
      };
}
