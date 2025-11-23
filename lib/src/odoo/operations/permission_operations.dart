import '../../client/http_client.dart';
import '../../core/endpoints.dart';
import '../models/request/check_access_rights_request.dart';
import '../models/response/check_access_rights_response.dart';
import '../models/request/exists_request.dart';
import '../models/response/exists_response.dart';

/// Permission and utility operations
class PermissionOperations {
  final BridgeCoreHttpClient _client;

  PermissionOperations(this._client);

  /// Check if user has access rights for an operation
  ///
  /// Checks if the current user has permission to perform
  /// an operation (read, write, create, unlink) on a model.
  ///
  /// Example:
  /// ```dart
  /// final canDelete = await odoo.permissions.checkAccessRights(
  ///   model: 'sale.order',
  ///   operation: 'unlink',
  /// );
  ///
  /// if (canDelete.hasAccess!) {
  ///   // Show delete button
  /// }
  /// ```
  Future<CheckAccessRightsResponse> checkAccessRights({
    required String model,
    required String operation,
    bool raiseException = false,
  }) async {
    final request = CheckAccessRightsRequest(
      model: model,
      operation: operation,
      raiseException: raiseException,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.checkAccessRights,
      request.toJson(),
    );

    return CheckAccessRightsResponse.fromJson(response);
  }

  /// Check if records exist
  ///
  /// Returns only the IDs that actually exist in the database.
  /// Useful for validating record IDs before operations.
  ///
  /// Example:
  /// ```dart
  /// final existing = await odoo.permissions.exists(
  ///   model: 'res.partner',
  ///   ids: [1, 2, 999, 1000],
  /// );
  ///
  /// print('Existing IDs: ${existing.existingIds}');
  /// // Output: Existing IDs: [1, 2]
  /// ```
  Future<ExistsResponse> exists({
    required String model,
    required List<int> ids,
  }) async {
    final request = ExistsRequest(
      model: model,
      ids: ids,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.exists,
      request.toJson(),
    );

    return ExistsResponse.fromJson(response);
  }
}

