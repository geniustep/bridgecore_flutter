import '../../client/http_client.dart';
import '../../core/endpoints.dart';
import '../models/request/call_method_request.dart';
import '../models/response/call_method_response.dart';

/// Custom method operations
///
/// Operations for calling custom methods on Odoo models
class CustomOperations {
  final BridgeCoreHttpClient _client;

  CustomOperations(this._client);

  /// Call any custom method on a model
  ///
  /// Generic method caller that can invoke any public method
  /// on an Odoo model, including button actions.
  ///
  /// Example:
  /// ```dart
  /// // Call action_confirm on sale.order
  /// final result = await odoo.custom.callMethod(
  ///   model: 'sale.order',
  ///   method: 'action_confirm',
  ///   ids: [orderId],
  /// );
  ///
  /// // Call custom method with arguments
  /// final result = await odoo.custom.callMethod(
  ///   model: 'your.model',
  ///   method: 'your_custom_method',
  ///   args: [arg1, arg2],
  ///   kwargs: {'param1': value1},
  /// );
  /// ```
  Future<CallMethodResponse> callMethod({
    required String model,
    required String method,
    List<int>? ids,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
  }) async {
    final request = CallMethodRequest(
      model: model,
      method: method,
      ids: ids,
      args: args,
      kwargs: kwargs,
    );

    final response = await _client.post(
      BridgeCoreEndpoints.callMethod,
      request.toJson(),
    );

    return CallMethodResponse.fromJson(response);
  }

  /// Confirm a sales order
  ///
  /// Convenience method for confirming sales orders.
  /// Calls the `action_confirm` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionConfirm(
  ///   model: 'sale.order',
  ///   ids: [orderId],
  /// );
  /// ```
  Future<CallMethodResponse> actionConfirm({
    required String model,
    required List<int> ids,
  }) async {
    return callMethod(
      model: model,
      method: 'action_confirm',
      ids: ids,
    );
  }

  /// Cancel a record
  ///
  /// Convenience method for canceling records.
  /// Calls the `action_cancel` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionCancel(
  ///   model: 'sale.order',
  ///   ids: [orderId],
  /// );
  /// ```
  Future<CallMethodResponse> actionCancel({
    required String model,
    required List<int> ids,
  }) async {
    return callMethod(
      model: model,
      method: 'action_cancel',
      ids: ids,
    );
  }

  /// Set to draft
  ///
  /// Convenience method for setting records to draft state.
  /// Calls the `action_draft` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionDraft(
  ///   model: 'sale.order',
  ///   ids: [orderId],
  /// );
  /// ```
  Future<CallMethodResponse> actionDraft({
    required String model,
    required List<int> ids,
  }) async {
    return callMethod(
      model: model,
      method: 'action_draft',
      ids: ids,
    );
  }

  /// Post an invoice/journal entry
  ///
  /// Convenience method for posting accounting documents.
  /// Calls the `action_post` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionPost(
  ///   model: 'account.move',
  ///   ids: [invoiceId],
  /// );
  /// ```
  Future<CallMethodResponse> actionPost({
    required String model,
    required List<int> ids,
  }) async {
    return callMethod(
      model: model,
      method: 'action_post',
      ids: ids,
    );
  }
}

