/// Request model for default_get operation
///
/// Gets default values for fields when creating new records
class DefaultGetRequest {
  /// Model name (e.g., 'sale.order')
  final String model;

  /// Fields to get defaults for
  final List<String> fields;

  DefaultGetRequest({
    required this.model,
    required this.fields,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'fields': fields,
      };
}

