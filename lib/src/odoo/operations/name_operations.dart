import '../../client/http_client.dart';
import '../../core/endpoints.dart';
import '../models/request/name_create_request.dart';
import '../models/response/name_create_response.dart';

/// Name-related operations
///
/// Operations for searching, getting, and creating records by name
class NameOperations {
  final BridgeCoreHttpClient _client;

  NameOperations(this._client);

  /// Search for records by name
  ///
  /// Returns list of [id, name] pairs matching the search term.
  /// Perfect for autocomplete/search fields.
  ///
  /// Example:
  /// ```dart
  /// final results = await odoo.names.nameSearch(
  ///   model: 'res.partner',
  ///   name: 'john',
  ///   limit: 10,
  /// );
  ///
  /// for (var result in results) {
  ///   print('[${result[0]}] ${result[1]}');
  /// }
  /// ```
  Future<List<List<dynamic>>> nameSearch({
    required String model,
    String name = '',
    List<dynamic> domain = const [],
    int limit = 100,
  }) async {
    final response = await _client.post(
      BridgeCoreEndpoints.nameSearch,
      {
        'model': model,
        'name': name,
        'domain': domain,
        'limit': limit,
      },
    );

    final result = response['result'] as List;
    return result.cast<List<dynamic>>();
  }

  /// Get display names for record IDs
  ///
  /// Returns list of [id, name] pairs for given IDs.
  ///
  /// Example:
  /// ```dart
  /// final names = await odoo.names.nameGet(
  ///   model: 'res.partner',
  ///   ids: [1, 2, 3],
  /// );
  ///
  /// print(names); // [[1, 'Company A'], [2, 'Company B'], ...]
  /// ```
  Future<List<List<dynamic>>> nameGet({
    required String model,
    required List<int> ids,
  }) async {
    final response = await _client.post(
      BridgeCoreEndpoints.nameGet,
      {
        'model': model,
        'ids': ids,
      },
    );

    final result = response['result'] as List;
    return result.cast<List<dynamic>>();
  }

  /// Create a record by name only
  ///
  /// Quick way to create a record with just a name.
  /// Useful for creating related records on-the-fly.
  ///
  /// Example:
  /// ```dart
  /// final result = await odoo.names.nameCreate(
  ///   model: 'res.partner',
  ///   name: 'New Customer',
  /// );
  ///
  /// print('Created ID: ${result.id}');
  /// print('Created name: ${result.name}');
  /// ```
  Future<NameCreateResponse> nameCreate({
    required String model,
    required String name,
  }) async {
    final request = NameCreateRequest(
      model: model,
      name: name,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.nameCreate,
      request.toJson(),
    );

    return NameCreateResponse.fromJson(response);
  }
}

