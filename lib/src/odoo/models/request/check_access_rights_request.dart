/// Request model for check_access_rights operation
class CheckAccessRightsRequest {
  /// Model name
  final String model;

  /// Operation to check ('read', 'write', 'create', 'unlink')
  final String operation;

  /// Raise exception if access denied
  final bool raiseException;

  CheckAccessRightsRequest({
    required this.model,
    required this.operation,
    this.raiseException = false,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'operation': operation,
        'raise_exception': raiseException,
      };
}

