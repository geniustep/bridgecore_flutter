/// Request model for copy operation
///
/// Duplicates a record with optional default values
class CopyRequest {
  /// Model name (e.g., 'product.template')
  final String model;

  /// ID of record to copy
  final int id;

  /// Default values for the new record
  final Map<String, dynamic>? defaultValues;

  CopyRequest({
    required this.model,
    required this.id,
    this.defaultValues,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'id': id,
        if (defaultValues != null) 'default': defaultValues,
      };
}

