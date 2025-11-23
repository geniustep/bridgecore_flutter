/// Request model for onchange operation
///
/// Onchange is used to automatically calculate field values when a field changes.
/// This is essential for:
/// - Price calculations when product changes
/// - Tax calculations
/// - Discount applications
/// - Payment term updates
/// - And many other dynamic form behaviors
class OnchangeRequest {
  /// Model name (e.g., 'sale.order.line')
  final String model;

  /// Record IDs (empty list for new records)
  final List<int> ids;

  /// Current field values
  final Map<String, dynamic> values;

  /// Field that changed (triggers the onchange)
  final String field;

  /// Specification of which fields have onchange methods
  /// Format: {'field_name': '1', ...}
  /// '1' means the field has an onchange method
  final Map<String, dynamic> spec;

  OnchangeRequest({
    required this.model,
    this.ids = const [],
    required this.values,
    required this.field,
    required this.spec,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'ids': ids,
        'values': values,
        'field': field,
        'spec': spec,
      };
}

