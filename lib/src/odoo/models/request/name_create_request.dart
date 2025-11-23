/// Request model for name_create operation
class NameCreateRequest {
  /// Model name
  final String model;

  /// Name for the new record
  final String name;

  NameCreateRequest({
    required this.model,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'name': name,
      };
}

