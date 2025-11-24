# Odoo 18 Integration Guide

Complete guide for using BridgeCore Flutter SDK with Odoo 18.

## Table of Contents

- [What's New in Odoo 18 Support](#whats-new-in-odoo-18-support)
- [Context Management](#context-management)
- [Call Methods](#call-methods)
- [Action Methods](#action-methods)
- [Action Results](#action-results)
- [Examples](#examples)

---

## What's New in Odoo 18 Support

### ✨ New Features

1. **Context Support** - Full support for Odoo context (language, timezone, company)
2. **callKw Method** - Generic Odoo RPC caller compatible with execute_kw
3. **7 New Action Methods** - validate, done, approve, reject, assign, unlock, executeButtonAction
4. **Enhanced Error Handling** - Detailed error information from Odoo 18
5. **Action Result Handler** - Parse and handle window actions
6. **OdooContext Manager** - Global context management

### 🚨 Important Changes

- XML-RPC and JSON-RPC endpoints will be deprecated in Odoo 20 (fall 2026)
- Context is now essential for multi-language and multi-company support
- Action methods can return action dictionaries (window actions, reports, etc.)

---

## Context Management

Context is crucial in Odoo 18 for:
- 🌐 Multi-language support
- 🕐 Timezone handling
- 🏢 Multi-company operations
- 🔑 Permission checking
- 📊 Custom business logic

### Setting Default Context

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// Set default context at app startup
void initializeApp() {
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
  );

  // Set default context for all operations
  OdooContext.setDefault(
    lang: 'ar_001',              // Arabic language
    timezone: 'Asia/Riyadh',     // Saudi Arabia timezone
    allowedCompanyIds: [1, 2],   // Multi-company access
  );
}
```

### Using Context in Calls

```dart
// Context is automatically merged
await BridgeCore.instance.odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
  context: {'lang': 'ar_001'}, // Overrides default
);

// Or use default context (set globally)
await BridgeCore.instance.odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
);
```

### Updating Context

```dart
// Update language only
OdooContext.setLanguage('ar_001');

// Update timezone only
OdooContext.setTimezone('Asia/Riyadh');

// Update specific values
OdooContext.update(
  lang: 'en_US',
  custom: {'my_custom_key': 'value'},
);

// Clear context
OdooContext.clear();
```

---

## Call Methods

### 1. callMethod - Simplified Method Caller

Best for button actions and simple method calls.

```dart
// Basic usage
final result = await BridgeCore.instance.odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);

// With arguments and kwargs
final result = await BridgeCore.instance.odoo.custom.callMethod(
  model: 'product.template',
  method: 'get_product_variants',
  ids: [productId],
  args: [{'color': 'red'}],
  kwargs: {'limit': 10},
  context: {'lang': 'ar_001'},
);

// Check result
if (result.success) {
  print('Success: ${result.result}');

  // Check if result is an action
  if (result.isAction) {
    print('Returned action: ${result.action?['type']}');
  }

  // Check for warnings
  if (result.hasWarnings) {
    print('Warnings: ${result.warnings}');
  }
} else {
  print('Error: ${result.error}');
  print('Details: ${result.errorDetails}');
}
```

### 2. callKw - Generic RPC Caller

Most compatible with Odoo's execute_kw pattern. Use when you need full control.

```dart
// Search and read
final result = await BridgeCore.instance.odoo.custom.callKw(
  model: 'res.partner',
  method: 'search_read',
  args: [
    [['is_company', '=', true]], // Domain
  ],
  kwargs: {
    'fields': ['name', 'email', 'phone'],
    'limit': 10,
    'offset': 0,
  },
  context: {'lang': 'ar_001'},
);

// Call button method
final result = await BridgeCore.instance.odoo.custom.callKw(
  model: 'sale.order',
  method: 'action_confirm',
  args: [[orderId]], // Note: IDs wrapped in list
  context: {'tz': 'Asia/Riyadh'},
);

// Create record
final result = await BridgeCore.instance.odoo.custom.callKw(
  model: 'res.partner',
  method: 'create',
  args: [
    {
      'name': 'شركة جديدة',
      'email': 'info@company.sa',
      'is_company': true,
    }
  ],
  context: {'lang': 'ar_001'},
);
```

---

## Action Methods

Pre-built convenience methods for common Odoo actions.

### Standard Actions (Existing)

```dart
// Confirm (sales orders, purchase orders)
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);

// Cancel
await odoo.custom.actionCancel(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);

// Set to draft
await odoo.custom.actionDraft(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);

// Post (accounting documents)
await odoo.custom.actionPost(
  model: 'account.move',
  ids: [invoiceId],
  context: {'lang': 'ar_001'},
);
```

### New Actions (Odoo 18)

```dart
// Validate (stock pickings, inventory)
await odoo.custom.actionValidate(
  model: 'stock.picking',
  ids: [pickingId],
  context: {'lang': 'ar_001'},
);

// Mark as done (purchase orders, manufacturing)
await odoo.custom.actionDone(
  model: 'purchase.order',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);

// Alternative method name
await odoo.custom.actionDone(
  model: 'mrp.production',
  ids: [productionId],
  methodName: 'button_mark_done',
  context: {'lang': 'ar_001'},
);

// Approve (HR leaves, expenses)
await odoo.custom.actionApprove(
  model: 'hr.leave',
  ids: [leaveId],
  context: {'lang': 'ar_001'},
);

// Reject/Refuse (approval workflows)
await odoo.custom.actionReject(
  model: 'hr.leave',
  ids: [leaveId],
  context: {'lang': 'ar_001'},
);

// Alternative method name
await odoo.custom.actionReject(
  model: 'hr.expense',
  ids: [expenseId],
  methodName: 'action_reject',
  context: {'lang': 'ar_001'},
);

// Assign (stock picking, tasks)
await odoo.custom.actionAssign(
  model: 'stock.picking',
  ids: [pickingId],
  context: {'lang': 'ar_001'},
);

// Unlock (posted accounting entries)
await odoo.custom.actionUnlock(
  model: 'account.move',
  ids: [moveId],
  context: {'lang': 'ar_001'},
);

// Generic button action
await odoo.custom.executeButtonAction(
  model: 'sale.order',
  buttonMethod: 'action_quotation_send',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);
```

---

## Action Results

When a method returns an action (e.g., opening a form, wizard), you can parse it using `ActionResult`.

### Handling Window Actions

```dart
final result = await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_view_order',
  ids: [orderId],
);

if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);

  print('Action type: ${action.type}');
  print('Model: ${action.resModel}');
  print('View mode: ${action.viewMode}');
  print('Record ID: ${action.resId}');

  // Check action type
  if (action.isWindowAction) {
    print('Opens window action');

    if (action.opensInNewWindow) {
      // Open in new window/dialog
    } else {
      // Open in current view
    }

    if (action.isFormView) {
      // Navigate to form view
      navigateToForm(action.resModel!, action.resId!);
    } else if (action.isListView) {
      // Navigate to list view
      navigateToList(action.resModel!, action.domain);
    }
  } else if (action.isReportAction) {
    // Download/display report
    print('Report: ${action.reportName}');
  } else if (action.isUrlAction) {
    // Open URL
    print('URL: ${action.url}');
  }
}
```

### Action Types

```dart
// Window action (most common)
action.isWindowAction  // ir.actions.act_window

// URL action
action.isUrlAction     // ir.actions.act_url

// Report action
action.isReportAction  // ir.actions.report

// Client action
action.isClientAction  // ir.actions.client

// Server action
action.isServerAction  // ir.actions.server
```

---

## Examples

### Complete Example: Sales Order Workflow

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class SalesOrderService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> createAndConfirmOrder() async {
    try {
      // Set Arabic context
      OdooContext.setDefault(
        lang: 'ar_001',
        timezone: 'Asia/Riyadh',
      );

      // 1. Create sales order
      final createResult = await odoo.custom.callKw(
        model: 'sale.order',
        method: 'create',
        args: [
          {
            'partner_id': 123,
            'date_order': DateTime.now().toIso8601String(),
          }
        ],
      );

      if (!createResult.success) {
        throw Exception(createResult.error);
      }

      final orderId = createResult.result as int;
      print('Created order: $orderId');

      // 2. Add order lines
      await odoo.custom.callKw(
        model: 'sale.order.line',
        method: 'create',
        args: [
          {
            'order_id': orderId,
            'product_id': 456,
            'product_uom_qty': 2.0,
          }
        ],
      );

      // 3. Confirm order
      final confirmResult = await odoo.custom.actionConfirm(
        model: 'sale.order',
        ids: [orderId],
      );

      if (confirmResult.success) {
        print('Order confirmed!');

        // Check if action returned
        if (confirmResult.isAction) {
          final action = ActionResult.fromJson(confirmResult.action!);
          print('Next action: ${action.type}');
        }

        // Check for warnings
        if (confirmResult.hasWarnings) {
          print('Warnings: ${confirmResult.warnings}');
        }
      } else {
        print('Confirmation failed: ${confirmResult.error}');
        print('Details: ${confirmResult.errorDetails}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

### Complete Example: HR Leave Approval

```dart
class HRLeaveService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> approveLeave(int leaveId) async {
    try {
      // Set context
      OdooContext.setDefault(lang: 'ar_001');

      // 1. Check if user can approve
      final accessCheck = await odoo.permissions.checkAccessRights(
        model: 'hr.leave',
        operation: 'write',
      );

      if (!accessCheck.hasAccess!) {
        throw Exception('لا تملك صلاحية الموافقة');
      }

      // 2. Validate leave request
      final validateResult = await odoo.custom.actionValidate(
        model: 'hr.leave',
        ids: [leaveId],
      );

      if (!validateResult.success) {
        throw Exception(validateResult.error);
      }

      // 3. Approve leave
      final approveResult = await odoo.custom.actionApprove(
        model: 'hr.leave',
        ids: [leaveId],
      );

      if (approveResult.success) {
        print('تمت الموافقة على الإجازة');
      } else {
        print('فشلت الموافقة: ${approveResult.error}');
      }
    } catch (e) {
      print('خطأ: $e');
    }
  }

  Future<void> rejectLeave(int leaveId, String reason) async {
    try {
      // Reject with reason in context
      final result = await odoo.custom.actionReject(
        model: 'hr.leave',
        ids: [leaveId],
        context: {
          'lang': 'ar_001',
          'reason': reason,
        },
      );

      if (result.success) {
        print('تم رفض الإجازة');
      }
    } catch (e) {
      print('خطأ: $e');
    }
  }
}
```

### Complete Example: Stock Picking Validation

```dart
class StockPickingService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> processPickingWorkflow(int pickingId) async {
    try {
      OdooContext.setDefault(lang: 'ar_001', timezone: 'Asia/Riyadh');

      // 1. Check availability
      final assignResult = await odoo.custom.actionAssign(
        model: 'stock.picking',
        ids: [pickingId],
      );

      if (!assignResult.success) {
        throw Exception('المنتجات غير متوفرة: ${assignResult.error}');
      }

      // 2. Validate transfer
      final validateResult = await odoo.custom.actionValidate(
        model: 'stock.picking',
        ids: [pickingId],
      );

      if (validateResult.success) {
        print('تم التحويل بنجاح');

        // Check if backorder created
        if (validateResult.isAction) {
          final action = ActionResult.fromJson(validateResult.action!);
          if (action.resModel == 'stock.backorder.confirmation') {
            print('يوجد كمية متبقية - تم إنشاء backorder');
          }
        }
      } else {
        print('فشل التحويل: ${validateResult.error}');
      }
    } catch (e) {
      print('خطأ: $e');
    }
  }
}
```

---

## Best Practices

### 1. Always Set Context for Arabic

```dart
OdooContext.setDefault(
  lang: 'ar_001',
  timezone: 'Asia/Riyadh',
);
```

### 2. Handle Actions Properly

```dart
final result = await odoo.custom.callMethod(...);

if (result.isAction) {
  // Handle returned action (wizard, form, etc.)
  final action = ActionResult.fromJson(result.action!);
  // Navigate or process action
}
```

### 3. Check Warnings

```dart
if (result.hasWarnings) {
  // Show warnings to user
  for (var warning in result.warnings!) {
    showWarning(warning['message']);
  }
}
```

### 4. Handle Errors with Details

```dart
if (!result.success) {
  print('Error: ${result.error}');

  if (result.errorDetails != null) {
    print('Error code: ${result.errorDetails?['code']}');
    print('Error data: ${result.errorDetails?['data']}');
  }
}
```

### 5. Use Appropriate Method

```dart
// ✅ Good: Use callMethod for button actions
await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
);

// ✅ Good: Use callKw for CRUD operations
await odoo.custom.callKw(
  model: 'res.partner',
  method: 'search_read',
  args: [[['is_company', '=', true]]],
);

// ✅ Good: Use convenience methods when available
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
);
```

---

## Migration from v1.x

If you're upgrading from an older version:

### Before (v1.x)

```dart
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
);
```

### After (v2.x with Odoo 18)

```dart
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001', 'tz': 'Asia/Riyadh'},
);
```

**Note:** Context is optional but highly recommended for Odoo 18.

---

## Troubleshooting

### Context not applied

**Problem:** Language or timezone not working

**Solution:** Set default context at app startup

```dart
OdooContext.setDefault(lang: 'ar_001', timezone: 'Asia/Riyadh');
```

### Method not found

**Problem:** `Method 'action_done' not found`

**Solution:** Some models use different method names

```dart
// Try alternative method name
await odoo.custom.actionDone(
  model: 'mrp.production',
  ids: [id],
  methodName: 'button_mark_done', // Different name
);
```

### Action not handled

**Problem:** Action result not displayed

**Solution:** Check if method returns action

```dart
if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);
  // Handle the action
}
```

---

## Support

For more information:
- Odoo 18 Documentation: https://www.odoo.com/documentation/18.0/
- BridgeCore Issues: https://github.com/your-repo/issues

---

**Last Updated:** 2025-11-24
**Odoo Version:** 18.0
**SDK Version:** 2.1.0
