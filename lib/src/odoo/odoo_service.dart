import '../client/http_client.dart';
import '../core/endpoints.dart';
import 'field_presets.dart';
import 'field_fallback_strategy.dart';
import 'operations/advanced_operations.dart';
import 'operations/view_operations.dart';
import 'operations/permission_operations.dart';
import 'operations/name_operations.dart';
import 'operations/custom_operations.dart';

/// Odoo operations service
///
/// Provides methods to interact with Odoo through BridgeCore API
///
/// All operations use tenant credentials automatically
class OdooService {
  final BridgeCoreHttpClient httpClient;

  // Active fallback strategies
  final Map<String, FieldFallbackStrategy> _activeStrategies = {};

  // New operation instances
  late final AdvancedOperations advanced;
  late final ViewOperations views;
  late final PermissionOperations permissions;
  late final NameOperations names;
  late final CustomOperations custom;

  OdooService({required this.httpClient}) {
    // Initialize new operations
    advanced = AdvancedOperations(httpClient);
    views = ViewOperations(httpClient);
    permissions = PermissionOperations(httpClient);
    names = NameOperations(httpClient);
    custom = CustomOperations(httpClient);
  }

  /// Search and read records
  ///
  /// Supports:
  /// - Field presets (FieldPreset.basic, .standard, etc.)
  /// - Smart field fallback (automatic retry on invalid fields)
  ///
  /// Example:
  /// ```dart
  /// final partners = await odoo.searchRead(
  ///   model: 'res.partner',
  ///   domain: [['is_company', '=', true]],
  ///   preset: FieldPreset.standard, // Use preset
  ///   limit: 50,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<dynamic> domain = const [],
    List<String>? fields,
    FieldPreset? preset,
    int limit = 80,
    int offset = 0,
    String? order,
    bool useSmartFallback = true,
  }) async {
    // Determine fields to use
    List<String>? finalFields = fields;

    // Use preset if provided
    if (preset != null && fields == null) {
      finalFields = FieldPresetsManager.getFields(model, preset);
    }

    // If smart fallback disabled or no fields, use direct call
    if (!useSmartFallback || finalFields == null) {
      return await _directSearchRead(
        model: model,
        domain: domain,
        fields: finalFields,
        limit: limit,
        offset: offset,
        order: order,
      );
    }

    // Use smart fallback strategy
    final strategyKey =
        '$model-searchRead-${DateTime.now().millisecondsSinceEpoch}';

    final strategy = FieldFallbackStrategy(
      model: model,
      onFieldsGet: (model) async {
        return await fieldsGet(model: model);
      },
    );

    strategy.initialize(finalFields);
    _activeStrategies[strategyKey] = strategy;

    try {
      final result = await _attemptSearchRead(
        strategy: strategy,
        model: model,
        domain: domain,
        limit: limit,
        offset: offset,
        order: order,
      );

      return result;
    } finally {
      _activeStrategies.remove(strategyKey);
    }
  }

  /// Attempt search read with fallback strategy
  Future<List<Map<String, dynamic>>> _attemptSearchRead({
    required FieldFallbackStrategy strategy,
    required String model,
    required List<dynamic> domain,
    required int limit,
    required int offset,
    String? order,
  }) async {
    final currentFields = strategy.getCurrentFields();

    try {
      return await _directSearchRead(
        model: model,
        domain: domain,
        fields: currentFields,
        limit: limit,
        offset: offset,
        order: order,
      );
    } catch (e) {
      final errorStr = e.toString();

      // Check if error is about invalid field
      if (errorStr.contains('Invalid field')) {
        try {
          final newFields = await strategy.handleInvalidField(errorStr);

          if (newFields != null && newFields.isNotEmpty) {
            // Retry with new fields
            return await _attemptSearchRead(
              strategy: strategy,
              model: model,
              domain: domain,
              limit: limit,
              offset: offset,
              order: order,
            );
          }
        } catch (strategyError) {
          throw Exception('Field fallback strategy exhausted: $strategyError');
        }
      }

      rethrow;
    }
  }

  /// Direct search read (without fallback)
  /// Uses call_kw endpoint to avoid rate limiting issues with search_read endpoint
  Future<List<Map<String, dynamic>>> _directSearchRead({
    required String model,
    List<dynamic> domain = const [],
    List<String>? fields,
    int limit = 80,
    int offset = 0,
    String? order,
  }) async {
    try {
      // Use call_kw endpoint instead of search_read to avoid rate limiting
      final kwargs = <String, dynamic>{
        'domain': domain,
        if (fields != null) 'fields': fields,
        'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
      };

      final response = await httpClient.post(
        BridgeCoreEndpoints.callKw,
        {
          'model': model,
          'method': 'search_read',
          'args': [],
          'kwargs': kwargs,
        },
      );

      // call_kw returns result directly
      final result = response['result'];
      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      }
      // Fallback for different response structures
      final list =
          (response['records'] ?? response['result']) as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      // Log which model failed for debugging
      print('❌ searchRead FAILED for model: $model');
      print('   Domain: $domain');
      print(
          '   Fields: ${fields?.take(5).toList()}${(fields?.length ?? 0) > 5 ? "... (${fields!.length} total)" : ""}');
      rethrow;
    }
  }

  /// Read records by IDs
  ///
  /// Example:
  /// ```dart
  /// final records = await odoo.read(
  ///   model: 'res.partner',
  ///   ids: [1, 2, 3],
  ///   fields: ['name', 'email'],
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> read({
    required String model,
    required List<int> ids,
    List<String>? fields,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final kwargs = <String, dynamic>{
      if (fields != null) 'fields': fields,
    };

    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'read',
        'args': [ids],
        'kwargs': kwargs,
      },
    );

    final result = response['result'] as List;
    return result.cast<Map<String, dynamic>>();
  }

  /// Create a new record
  ///
  /// Returns the ID of the created record
  ///
  /// Example:
  /// ```dart
  /// final id = await odoo.create(
  ///   model: 'res.partner',
  ///   values: {
  ///     'name': 'New Company',
  ///     'email': 'info@company.com',
  ///     'is_company': true,
  ///   },
  /// );
  /// ```
  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'create',
        'args': [values],
        'kwargs': {},
      },
    );

    return response['result'] as int;
  }

  /// Update existing records
  ///
  /// Returns true if successful
  ///
  /// Example:
  /// ```dart
  /// await odoo.update(
  ///   model: 'res.partner',
  ///   ids: [123],
  ///   values: {
  ///     'phone': '+966501234567',
  ///     'city': 'Riyadh',
  ///   },
  /// );
  /// ```
  Future<bool> update({
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'write',
        'args': [ids, values],
        'kwargs': {},
      },
    );

    return response['result'] as bool;
  }

  /// Delete records
  ///
  /// Returns true if successful
  ///
  /// Example:
  /// ```dart
  /// await odoo.delete(
  ///   model: 'res.partner',
  ///   ids: [123, 456],
  /// );
  /// ```
  Future<bool> delete({
    required String model,
    required List<int> ids,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'unlink',
        'args': [ids],
        'kwargs': {},
      },
    );

    return response['result'] as bool;
  }

  /// Search for record IDs only
  ///
  /// Example:
  /// ```dart
  /// final ids = await odoo.search(
  ///   model: 'res.partner',
  ///   domain: [['is_company', '=', true]],
  ///   limit: 10,
  /// );
  /// ```
  Future<List<int>> search({
    required String model,
    List<dynamic> domain = const [],
    int? limit,
    int offset = 0,
    String? order,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final kwargs = <String, dynamic>{
      if (limit != null) 'limit': limit,
      'offset': offset,
      if (order != null) 'order': order,
    };

    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'search',
        'args': [domain],
        'kwargs': kwargs,
      },
    );

    final result = response['result'] as List;
    return result.cast<int>();
  }

  /// Count records matching domain
  ///
  /// Example:
  /// ```dart
  /// final count = await odoo.searchCount(
  ///   model: 'res.partner',
  ///   domain: [['is_company', '=', true]],
  /// );
  /// print('Total companies: $count');
  /// ```
  Future<int> searchCount({
    required String model,
    List<dynamic> domain = const [],
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'search_count',
        'args': [domain],
        'kwargs': {},
      },
    );

    return response['result'] as int;
  }

  /// Get fields information for a model
  ///
  /// Example:
  /// ```dart
  /// final fields = await odoo.fieldsGet(
  ///   model: 'res.partner',
  /// );
  /// print(fields['name']?['type']); // 'char'
  /// ```
  Future<Map<String, dynamic>> fieldsGet({
    required String model,
    List<String>? fields,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final kwargs = <String, dynamic>{
      if (fields != null) 'allfields': fields,
    };

    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'fields_get',
        'args': [],
        'kwargs': kwargs,
      },
    );

    return response['result'] as Map<String, dynamic>;
  }

  /// Name search - search for records by name
  ///
  /// Returns list of [id, name] pairs
  ///
  /// Example:
  /// ```dart
  /// final results = await odoo.nameSearch(
  ///   model: 'res.partner',
  ///   name: 'Company',
  ///   limit: 10,
  /// );
  /// ```
  Future<List<List<dynamic>>> nameSearch({
    required String model,
    String name = '',
    List<dynamic> domain = const [],
    int limit = 100,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'name_search',
        'args': [name],
        'kwargs': {
          'args': domain,
          'limit': limit,
        },
      },
    );

    final result = response['result'] as List;
    return result.cast<List<dynamic>>();
  }

  /// Name get - get names for record IDs
  ///
  /// Returns list of [id, name] pairs
  ///
  /// Example:
  /// ```dart
  /// final names = await odoo.nameGet(
  ///   model: 'res.partner',
  ///   ids: [1, 2, 3],
  /// );
  /// ```
  Future<List<List<dynamic>>> nameGet({
    required String model,
    required List<int> ids,
  }) async {
    // Use call_kw endpoint to avoid rate limiting
    final response = await httpClient.post(
      BridgeCoreEndpoints.callKw,
      {
        'model': model,
        'method': 'name_get',
        'args': [ids],
        'kwargs': {},
      },
    );

    final result = response['result'] as List;
    return result.cast<List<dynamic>>();
  }

  // ════════════════════════════════════════════════════════════
  // Web Operations (Odoo 14+)
  // ════════════════════════════════════════════════════════════

  /// Web search read (Odoo 14+)
  ///
  /// Enhanced search read with web-specific features
  ///
  /// Example:
  /// ```dart
  /// final records = await odoo.webSearchRead(
  ///   model: 'res.partner',
  ///   domain: [['is_company', '=', true]],
  ///   fields: ['name', 'email'],
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> webSearchRead({
    required String model,
    List<dynamic> domain = const [],
    List<String>? fields,
    int limit = 80,
    int offset = 0,
    String? order,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.webSearchRead,
      {
        'model': model,
        'domain': domain,
        if (fields != null) 'fields': fields,
        'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
      },
    );

    final result = response['result'] as List;
    return result.cast<Map<String, dynamic>>();
  }

  /// Web read (Odoo 14+)
  ///
  /// Enhanced read with web-specific features
  ///
  /// Example:
  /// ```dart
  /// final records = await odoo.webRead(
  ///   model: 'res.partner',
  ///   ids: [1, 2, 3],
  ///   fields: ['name', 'email'],
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> webRead({
    required String model,
    required List<int> ids,
    List<String>? fields,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.webRead,
      {
        'model': model,
        'ids': ids,
        if (fields != null) 'fields': fields,
      },
    );

    final result = response['result'] as List;
    return result.cast<Map<String, dynamic>>();
  }

  /// Web save (Odoo 14+)
  ///
  /// Save records with web-specific features
  ///
  /// Example:
  /// ```dart
  /// await odoo.webSave(
  ///   model: 'res.partner',
  ///   records: [
  ///     {'id': 1, 'name': 'Updated Name'},
  ///     {'id': 0, 'name': 'New Record'},
  ///   ],
  /// );
  /// ```
  Future<bool> webSave({
    required String model,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.webSave,
      {
        'model': model,
        'records': records,
      },
    );

    return response['result'] as bool? ?? true;
  }

  // ════════════════════════════════════════════════════════════
  // Batch Operations
  // ════════════════════════════════════════════════════════════

  /// Batch create records
  ///
  /// Create multiple records in a single request
  ///
  /// Example:
  /// ```dart
  /// final ids = await odoo.batchCreate(
  ///   model: 'res.partner',
  ///   valuesList: [
  ///     {'name': 'Company 1', 'email': 'info1@company.com'},
  ///     {'name': 'Company 2', 'email': 'info2@company.com'},
  ///   ],
  /// );
  /// ```
  Future<List<int>> batchCreate({
    required String model,
    required List<Map<String, dynamic>> valuesList,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.batchCreate,
      {
        'model': model,
        'values_list': valuesList,
      },
    );

    final result = response['result'] as List;
    return result.cast<int>();
  }

  /// Batch update records
  ///
  /// Update multiple records in a single request
  ///
  /// Example:
  /// ```dart
  /// await odoo.batchUpdate(
  ///   model: 'res.partner',
  ///   updates: [
  ///     {'id': 1, 'values': {'phone': '+966501234567'}},
  ///     {'id': 2, 'values': {'phone': '+966509876543'}},
  ///   ],
  /// );
  /// ```
  Future<bool> batchUpdate({
    required String model,
    required List<Map<String, dynamic>> updates,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.batchWrite,
      {
        'model': model,
        'updates': updates,
      },
    );

    return response['result'] as bool? ?? true;
  }

  /// Batch delete records
  ///
  /// Delete multiple records in a single request
  ///
  /// Example:
  /// ```dart
  /// await odoo.batchDelete(
  ///   model: 'res.partner',
  ///   ids: [1, 2, 3, 4, 5],
  /// );
  /// ```
  Future<bool> batchDelete({
    required String model,
    required List<int> ids,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.batchUnlink,
      {
        'model': model,
        'ids': ids,
      },
    );

    return response['result'] as bool? ?? true;
  }

  /// Execute multiple operations in a single request
  ///
  /// Example:
  /// ```dart
  /// final results = await odoo.executeBatch([
  ///   {'method': 'search_read', 'model': 'res.partner', 'domain': []},
  ///   {'method': 'search_count', 'model': 'product.product', 'domain': []},
  /// ]);
  /// ```
  Future<List<dynamic>> executeBatch(
      List<Map<String, dynamic>> operations) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.batchExecute,
      {
        'operations': operations,
      },
    );

    final result = response['result'] as List;
    return result;
  }
}
