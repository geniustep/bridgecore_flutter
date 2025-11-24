import '../../client/http_client.dart';
import '../../core/endpoints.dart';
import '../models/request/call_method_request.dart';
import '../models/response/call_method_response.dart';
import '../models/request/call_kw_request.dart';
import '../models/response/call_kw_response.dart';
import '../odoo_context.dart';

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
  /// Supports Odoo 18 context for language, timezone, company, etc.
  ///
  /// Example:
  /// ```dart
  /// // Call action_confirm on sale.order
  /// final result = await odoo.custom.callMethod(
  ///   model: 'sale.order',
  ///   method: 'action_confirm',
  ///   ids: [orderId],
  ///   context: {'lang': 'ar_001', 'tz': 'Asia/Riyadh'},
  /// );
  ///
  /// // Call custom method with arguments
  /// final result = await odoo.custom.callMethod(
  ///   model: 'your.model',
  ///   method: 'your_custom_method',
  ///   args: [arg1, arg2],
  ///   kwargs: {'param1': value1},
  ///   context: {'lang': 'en_US'},
  /// );
  /// ```
  Future<CallMethodResponse> callMethod({
    required String model,
    required String method,
    List<int>? ids,
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
    Map<String, dynamic>? context,
  }) async {
    final request = CallMethodRequest(
      model: model,
      method: method,
      ids: ids,
      args: args,
      kwargs: kwargs,
      context: OdooContext.merge(context),
    );

    final response = await _client.post(
      BridgeCoreEndpoints.callMethod,
      request.toJson(),
    );

    return CallMethodResponse.fromJson(response);
  }

  /// Generic Odoo RPC caller (call_kw)
  ///
  /// Most compatible way to call any Odoo method using execute_kw pattern.
  /// Use this when you need full control over args and kwargs.
  ///
  /// Example:
  /// ```dart
  /// // Search and read partners
  /// final result = await odoo.custom.callKw(
  ///   model: 'res.partner',
  ///   method: 'search_read',
  ///   args: [[['is_company', '=', true]]],
  ///   kwargs: {
  ///     'fields': ['name', 'email'],
  ///     'limit': 10,
  ///   },
  ///   context: {'lang': 'ar_001'},
  /// );
  ///
  /// // Call button method
  /// final result = await odoo.custom.callKw(
  ///   model: 'sale.order',
  ///   method: 'action_confirm',
  ///   args: [[orderId]],
  ///   context: {'tz': 'Asia/Riyadh'},
  /// );
  /// ```
  Future<CallKwResponse> callKw({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
    Map<String, dynamic>? context,
  }) async {
    final request = CallKwRequest(
      model: model,
      method: method,
      args: args,
      kwargs: kwargs,
      context: OdooContext.merge(context),
    );

    final response = await _client.post(
      BridgeCoreEndpoints.callKw,
      request.toJson(),
    );

    return CallKwResponse.fromJson(response);
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
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionConfirm({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_confirm',
      ids: ids,
      context: context,
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
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionCancel({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_cancel',
      ids: ids,
      context: context,
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
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionDraft({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_draft',
      ids: ids,
      context: context,
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
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionPost({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_post',
      ids: ids,
      context: context,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Additional Common Actions (Odoo 18)
  // ═══════════════════════════════════════════════════════════════

  /// Validate a record
  ///
  /// Common in many Odoo models for validation step.
  /// Calls the `action_validate` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionValidate(
  ///   model: 'stock.picking',
  ///   ids: [pickingId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionValidate({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_validate',
      ids: ids,
      context: context,
    );
  }

  /// Mark a record as done
  ///
  /// Used in manufacturing, purchase orders, etc.
  /// Calls the `action_done` or `button_done` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionDone(
  ///   model: 'purchase.order',
  ///   ids: [orderId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionDone({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
    String methodName = 'action_done',
  }) async {
    return callMethod(
      model: model,
      method: methodName,
      ids: ids,
      context: context,
    );
  }

  /// Approve a record
  ///
  /// Used in HR leaves, expenses, etc.
  /// Calls the `action_approve` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionApprove(
  ///   model: 'hr.leave',
  ///   ids: [leaveId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionApprove({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_approve',
      ids: ids,
      context: context,
    );
  }

  /// Reject a record
  ///
  /// Used in approval workflows.
  /// Calls the `action_refuse` or `action_reject` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionReject(
  ///   model: 'hr.leave',
  ///   ids: [leaveId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionReject({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
    String methodName = 'action_refuse',
  }) async {
    return callMethod(
      model: model,
      method: methodName,
      ids: ids,
      context: context,
    );
  }

  /// Assign records
  ///
  /// Used in stock picking, tasks, etc.
  /// Calls the `action_assign` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionAssign(
  ///   model: 'stock.picking',
  ///   ids: [pickingId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionAssign({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: 'action_assign',
      ids: ids,
      context: context,
    );
  }

  /// Unlock a record
  ///
  /// Used in accounting to unlock posted entries.
  /// Calls the `button_draft` or `action_unlock` method.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.actionUnlock(
  ///   model: 'account.move',
  ///   ids: [moveId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> actionUnlock({
    required String model,
    required List<int> ids,
    Map<String, dynamic>? context,
    String methodName = 'button_draft',
  }) async {
    return callMethod(
      model: model,
      method: methodName,
      ids: ids,
      context: context,
    );
  }

  /// Execute a button action
  ///
  /// Generic method to call any button action by name.
  /// Useful when you know the button/method name.
  ///
  /// Example:
  /// ```dart
  /// await odoo.custom.executeButtonAction(
  ///   model: 'sale.order',
  ///   buttonMethod: 'action_quotation_send',
  ///   ids: [orderId],
  ///   context: {'lang': 'ar_001'},
  /// );
  /// ```
  Future<CallMethodResponse> executeButtonAction({
    required String model,
    required String buttonMethod,
    required List<int> ids,
    Map<String, dynamic>? context,
  }) async {
    return callMethod(
      model: model,
      method: buttonMethod,
      ids: ids,
      context: context,
    );
  }
}

