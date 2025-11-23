import '../../client/http_client.dart';
import '../../core/endpoints.dart';
import '../models/request/fields_view_get_request.dart';
import '../models/response/fields_view_get_response.dart';
import '../models/request/load_views_request.dart';
import '../models/response/load_views_response.dart';
import '../models/request/get_views_request.dart';
import '../models/response/get_views_response.dart';

/// View operations for Odoo
///
/// Provides operations for loading view definitions and metadata
class ViewOperations {
  final BridgeCoreHttpClient _client;

  ViewOperations(this._client);

  /// Get view definition (Odoo ≤15)
  ///
  /// **Note:** In Odoo 16+, use `getView()` instead.
  ///
  /// Gets the definition of a view (form, tree, kanban, etc.)
  /// including architecture (XML), fields, and toolbar.
  ///
  /// Example:
  /// ```dart
  /// final view = await odoo.views.fieldsViewGet(
  ///   model: 'res.partner',
  ///   viewType: 'form',
  /// );
  ///
  /// print('View ID: ${view.viewId}');
  /// print('Fields: ${view.fields?.keys}');
  /// ```
  Future<FieldsViewGetResponse> fieldsViewGet({
    required String model,
    int? viewId,
    required String viewType,
    bool toolbar = false,
    bool submenu = false,
  }) async {
    final request = FieldsViewGetRequest(
      model: model,
      viewId: viewId,
      viewType: viewType,
      toolbar: toolbar,
      submenu: submenu,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.fieldsViewGet,
      request.toJson(),
    );

    return FieldsViewGetResponse.fromJson(response);
  }

  /// Get view definition (Odoo 16+)
  ///
  /// Modern replacement for `fieldsViewGet()`.
  /// Same functionality but updated API.
  ///
  /// Example:
  /// ```dart
  /// final view = await odoo.views.getView(
  ///   model: 'res.partner',
  ///   viewType: 'form',
  /// );
  /// ```
  Future<FieldsViewGetResponse> getView({
    required String model,
    int? viewId,
    required String viewType,
    Map<String, dynamic>? options,
  }) async {
    final request = {
      'model': model,
      if (viewId != null) 'view_id': viewId,
      'view_type': viewType,
      if (options != null) ...options,
    };

    final response = await _client.post(
      BridgeCoreEndpoints.getView,
      request,
    );

    return FieldsViewGetResponse.fromJson(response);
  }

  /// Load multiple views at once (Odoo ≤15)
  ///
  /// **Note:** In Odoo 16+, use `getViews()` instead.
  ///
  /// Efficiently loads multiple views in a single request.
  /// Useful for loading form + list views together.
  ///
  /// Example:
  /// ```dart
  /// final views = await odoo.views.loadViews(
  ///   model: 'res.partner',
  ///   views: [
  ///     [null, 'form'],
  ///     [null, 'tree'],
  ///     [null, 'kanban'],
  ///   ],
  ///   loadFilters: true,
  /// );
  ///
  /// print('Form view: ${views.views?['form']}');
  /// print('Tree view: ${views.views?['tree']}');
  /// ```
  Future<LoadViewsResponse> loadViews({
    required String model,
    required List<List<dynamic>> views,
    bool loadAction = false,
    bool loadFilters = false,
  }) async {
    final request = LoadViewsRequest(
      model: model,
      views: views,
      loadAction: loadAction,
      loadFilters: loadFilters,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.loadViews,
      request.toJson(),
    );

    return LoadViewsResponse.fromJson(response);
  }

  /// Load multiple views at once (Odoo 16+)
  ///
  /// Modern replacement for `loadViews()`.
  /// More efficient and cleaner API.
  ///
  /// Example:
  /// ```dart
  /// final views = await odoo.views.getViews(
  ///   model: 'res.partner',
  ///   views: [
  ///     [null, 'form'],
  ///     [null, 'list'], // Note: 'list' instead of 'tree' in Odoo 16+
  ///   ],
  /// );
  /// ```
  Future<GetViewsResponse> getViews({
    required String model,
    required List<List<dynamic>> views,
    Map<String, dynamic>? options,
  }) async {
    final request = GetViewsRequest(
      model: model,
      views: views,
      options: options,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.getViews,
      request.toJson(),
    );

    return GetViewsResponse.fromJson(response);
  }
}

