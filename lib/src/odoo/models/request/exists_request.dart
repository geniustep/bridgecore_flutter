/// Request model for exists operation
class ExistsRequest {
  /// Model name
  final String model;

  /// Record IDs to check
  final List<int> ids;

  ExistsRequest({
    required this.model,
    required this.ids,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'ids': ids,
      };
}

