import '../../client/http_client.dart';
import '../../core/endpoints.dart';
import '../models/request/onchange_request.dart';
import '../models/response/onchange_response.dart';
import '../models/request/read_group_request.dart';
import '../models/response/read_group_response.dart';
import '../models/request/default_get_request.dart';
import '../models/response/default_get_response.dart';
import '../models/request/copy_request.dart';
import '../models/response/copy_response.dart';

/// Advanced Odoo operations
///
/// Provides advanced operations like onchange, read_group, default_get, and copy
class AdvancedOperations {
  final BridgeCoreHttpClient _client;

  AdvancedOperations(this._client);

  /// Execute onchange - Calculate field values automatically
  ///
  /// This is **CRITICAL** for forms. Onchange is used when a field changes
  /// to automatically calculate other field values. Essential for:
  /// - Price calculations when product changes
  /// - Tax calculations
  /// - Discount applications
  /// - Payment term updates
  /// - Quantity/UOM conversions
  ///
  /// Example:
  /// ```dart
  /// final result = await odoo.advanced.onchange(
  ///   model: 'sale.order.line',
  ///   values: {
  ///     'order_id': 1,
  ///     'product_id': 5,
  ///     'product_uom_qty': 2.0,
  ///   },
  ///   field: 'product_id', // Field that changed
  ///   spec: {
  ///     'product_id': '1',
  ///     'price_unit': '1',
  ///     'discount': '1',
  ///   },
  /// );
  ///
  /// // Use the calculated values
  /// print('Price: ${result.value?['price_unit']}');
  /// print('Discount: ${result.value?['discount']}');
  /// ```
  Future<OnchangeResponse> onchange({
    required String model,
    List<int> ids = const [],
    required Map<String, dynamic> values,
    required String field,
    required Map<String, dynamic> spec,
  }) async {
    final request = OnchangeRequest(
      model: model,
      ids: ids,
      values: values,
      field: field,
      spec: spec,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.onchange,
      request.toJson(),
    );

    return OnchangeResponse.fromJson(response);
  }

  /// Read grouped data - Essential for reports and analytics
  ///
  /// Groups records and aggregates data. Perfect for:
  /// - Sales reports by customer
  /// - Revenue by month
  /// - Product sales by category
  /// - Any dashboard statistics
  ///
  /// Example:
  /// ```dart
  /// final report = await odoo.advanced.readGroup(
  ///   model: 'sale.order',
  ///   domain: [['state', '=', 'sale']],
  ///   fields: ['amount_total'],
  ///   groupby: ['partner_id'],
  ///   orderby: 'amount_total desc',
  ///   limit: 10,
  /// );
  ///
  /// for (var group in report.groups!) {
  ///   print('${group['partner_id'][1]}: \$${group['amount_total']}');
  /// }
  /// ```
  Future<ReadGroupResponse> readGroup({
    required String model,
    List<dynamic> domain = const [],
    required List<String> fields,
    required List<String> groupby,
    int? offset,
    int? limit,
    String? orderby,
    bool lazy = true,
  }) async {
    final request = ReadGroupRequest(
      model: model,
      domain: domain,
      fields: fields,
      groupby: groupby,
      offset: offset,
      limit: limit,
      orderby: orderby,
      lazy: lazy,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.readGroup,
      request.toJson(),
    );

    return ReadGroupResponse.fromJson(response);
  }

  /// Get default values for fields
  ///
  /// Gets default values when creating new records.
  /// Useful for pre-filling forms with default values.
  ///
  /// Example:
  /// ```dart
  /// final defaults = await odoo.advanced.defaultGet(
  ///   model: 'sale.order',
  ///   fields: ['partner_id', 'date_order', 'pricelist_id'],
  /// );
  ///
  /// // Use defaults in your form
  /// print('Default pricelist: ${defaults.defaults?['pricelist_id']}');
  /// ```
  Future<DefaultGetResponse> defaultGet({
    required String model,
    required List<String> fields,
  }) async {
    final request = DefaultGetRequest(
      model: model,
      fields: fields,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.defaultGet,
      request.toJson(),
    );

    return DefaultGetResponse.fromJson(response);
  }

  /// Copy/duplicate a record
  ///
  /// Creates a copy of an existing record with optional default values.
  ///
  /// Example:
  /// ```dart
  /// final newId = await odoo.advanced.copy(
  ///   model: 'product.template',
  ///   id: 123,
  ///   defaultValues: {
  ///     'name': 'Copy of Product',
  ///     'default_code': 'COPY-001',
  ///   },
  /// );
  ///
  /// print('Created copy with ID: ${newId.newId}');
  /// ```
  Future<CopyResponse> copy({
    required String model,
    required int id,
    Map<String, dynamic>? defaultValues,
  }) async {
    final request = CopyRequest(
      model: model,
      id: id,
      defaultValues: defaultValues,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.copy,
      request.toJson(),
    );

    return CopyResponse.fromJson(response);
  }
}

