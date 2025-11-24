# BridgeCore Flutter SDK v2.1.0

Official Flutter SDK for BridgeCore API - Complete Odoo 18 integration with full context management.

## 🎉 What's New in v2.1.0

- ✅ **Full Odoo 18 Support** - Context management, enhanced errors, action handling
- ✅ **Context Manager** - Global context for language, timezone, and multi-company
- ✅ **7 New Action Methods** - validate, done, approve, reject, assign, unlock, executeButtonAction
- ✅ **callKw Method** - Generic RPC caller compatible with execute_kw
- ✅ **Action Result Handler** - Parse and handle window actions, reports, wizards
- ✅ **Enhanced Error Handling** - Detailed error information from Odoo 18

## ✨ Features

### Core Features
- ✅ **Easy Authentication** - Login, refresh, logout with automatic token management
- ✅ **33 Odoo Operations** - Complete CRUD, search, advanced, views, permissions, and custom operations
- ✅ **Odoo 18 Context** - Full support for language, timezone, company context
- ✅ **Auto Token Refresh** - Automatic token refresh on expiry
- ✅ **Comprehensive Exceptions** - 10 specialized exception types
- ✅ **Null Safety** - Full null safety support
- ✅ **Type Safe** - Strongly typed models and responses

### Odoo 18 Features 🆕
- ✅ **OdooContext Manager** 🆕 - Global context management (language, timezone, company)
- ✅ **callKw Method** 🆕 - Generic RPC caller (execute_kw compatible)
- ✅ **7 New Actions** 🆕 - Validate, Done, Approve, Reject, Assign, Unlock, ExecuteButton
- ✅ **Action Results** 🆕 - Parse window actions, reports, URLs
- ✅ **Enhanced Errors** 🆕 - Detailed error info with codes and data
- ✅ **Arabic Support** 🆕 - Full RTL and Arabic language support

### Advanced Features
- ✅ **Onchange Support** - Auto-calculate field values (critical for forms)
- ✅ **Read Group** - Aggregate data for reports and analytics
- ✅ **Permission Checking** - Check user access rights
- ✅ **View Operations** - Load view definitions dynamically
- ✅ **Custom Methods** - Call any Odoo method
- ✅ **Odoo Fields Check** - Verify custom fields during login
- ✅ **Field Presets** - Predefined field lists for common models
- ✅ **Smart Fallback** - Automatic retry on invalid fields
- ✅ **Retry Interceptor** - Automatic retry on network errors
- ✅ **Caching** - In-memory caching with TTL support
- ✅ **Metrics & Logging** - Request tracking and logging system

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  bridgecore_flutter:
    path: ../bridgecore_flutter  # For local development
```

## 🚀 Quick Start

### 1. Initialize with Odoo 18 Context

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  // Initialize SDK
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
    debugMode: true,
    enableCache: true,
    enableLogging: true,
    logLevel: LogLevel.info,
  );

  // Set default Odoo 18 context (optional but recommended)
  OdooContext.setDefault(
    lang: 'ar_001',              // Arabic language
    timezone: 'Asia/Riyadh',     // Saudi Arabia timezone
    allowedCompanyIds: [1, 2],   // Multi-company support
  );

  runApp(MyApp());
}
```

### 2. Login

```dart
try {
  final session = await BridgeCore.instance.auth.login(
    email: 'user@company.com',
    password: 'password123',
  );

  print('Logged in as: ${session.user.fullName}');
  print('Tenant: ${session.tenant.name}');
  print('Token expires in: ${session.expiresIn}s');
} on PaymentRequiredException catch (e) {
  print('Please upgrade your account');
} on TenantSuspendedException catch (e) {
  print('Account suspended: ${e.message}');
} on UnauthorizedException catch (e) {
  print('Login failed: ${e.message}');
}
```

### 3. Use Odoo 18 Operations

```dart
// Basic search with Arabic context
final partners = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  fields: ['name', 'email', 'phone'],
  limit: 50,
);

// Call custom method with context
final result = await BridgeCore.instance.odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
  context: {'lang': 'ar_001', 'tz': 'Asia/Riyadh'},
);

// Use callKw for advanced operations
final kwResult = await BridgeCore.instance.odoo.custom.callKw(
  model: 'res.partner',
  method: 'search_read',
  args: [[['country_id.code', '=', 'SA']]],
  kwargs: {'fields': ['name', 'email'], 'limit': 10},
  context: {'lang': 'ar_001'},
);
```

## 📚 Odoo 18 Context Management

### Setting Global Context

```dart
// Set default context for all operations
OdooContext.setDefault(
  lang: 'ar_001',              // Language
  timezone: 'Asia/Riyadh',     // Timezone
  allowedCompanyIds: [1, 2],   // Multi-company
  uid: userId,                 // User ID
  custom: {                    // Custom context
    'custom_key': 'value',
  },
);
```

### Using Context in Calls

```dart
// Context is automatically merged with default
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'}, // Overrides default
);

// Or use default context (set globally)
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
);
```

### Context Helper Methods

```dart
// Update language
OdooContext.setLanguage('ar_001');

// Update timezone
OdooContext.setTimezone('Asia/Riyadh');

// Update specific values
OdooContext.update(lang: 'en_US');

// Clear context
OdooContext.clear();
```

## 🎯 Odoo 18 Action Methods

### Standard Actions

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
);

// Set to draft
await odoo.custom.actionDraft(
  model: 'sale.order',
  ids: [orderId],
);

// Post (accounting documents)
await odoo.custom.actionPost(
  model: 'account.move',
  ids: [invoiceId],
);
```

### New Odoo 18 Actions 🆕

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
);

// Approve (HR leaves, expenses)
await odoo.custom.actionApprove(
  model: 'hr.leave',
  ids: [leaveId],
  context: {'lang': 'ar_001'},
);

// Reject (approval workflows)
await odoo.custom.actionReject(
  model: 'hr.leave',
  ids: [leaveId],
);

// Assign (stock picking, tasks)
await odoo.custom.actionAssign(
  model: 'stock.picking',
  ids: [pickingId],
);

// Unlock (posted accounting entries)
await odoo.custom.actionUnlock(
  model: 'account.move',
  ids: [moveId],
);

// Execute any button action
await odoo.custom.executeButtonAction(
  model: 'sale.order',
  buttonMethod: 'action_quotation_send',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);
```

## 🔄 Call Methods

### callMethod - Simplified Method Caller

```dart
final result = await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
  args: [additionalArgs],
  kwargs: {'param': 'value'},
  context: {'lang': 'ar_001'},
);

// Check result
if (result.success) {
  print('Success: ${result.result}');

  // Check for action
  if (result.isAction) {
    print('Action: ${result.action}');
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

### callKw - Generic RPC Caller 🆕

Most compatible with Odoo's execute_kw pattern:

```dart
final result = await odoo.custom.callKw(
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
  context: {'lang': 'ar_001', 'tz': 'Asia/Riyadh'},
);
```

## 🎨 Action Result Handler 🆕

Handle window actions, reports, and wizards:

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

  if (action.isWindowAction) {
    if (action.isFormView) {
      // Navigate to form view
      navigateToForm(action.resModel!, action.resId!);
    } else if (action.isListView) {
      // Navigate to list view
      navigateToList(action.resModel!, action.domain);
    }
  } else if (action.isReportAction) {
    // Download report
    downloadReport(action.reportName!);
  } else if (action.isUrlAction) {
    // Open URL
    openUrl(action.url!);
  }
}
```

## 📖 Complete Examples

### Example 1: Sales Order Workflow (Arabic)

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
        print('تم تأكيد الطلب بنجاح!');

        if (confirmResult.isAction) {
          final action = ActionResult.fromJson(confirmResult.action!);
          print('Next action: ${action.type}');
        }
      } else {
        print('فشل التأكيد: ${confirmResult.error}');
      }
    } catch (e) {
      print('خطأ: $e');
    }
  }
}
```

### Example 2: HR Leave Approval

```dart
class HRLeaveService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> approveLeave(int leaveId) async {
    try {
      // Check permissions
      final accessCheck = await odoo.permissions.checkAccessRights(
        model: 'hr.leave',
        operation: 'write',
      );

      if (!accessCheck.hasAccess!) {
        throw Exception('لا تملك صلاحية الموافقة');
      }

      // Validate leave
      final validateResult = await odoo.custom.actionValidate(
        model: 'hr.leave',
        ids: [leaveId],
        context: {'lang': 'ar_001'},
      );

      if (!validateResult.success) {
        throw Exception(validateResult.error);
      }

      // Approve leave
      final approveResult = await odoo.custom.actionApprove(
        model: 'hr.leave',
        ids: [leaveId],
        context: {'lang': 'ar_001'},
      );

      if (approveResult.success) {
        print('تمت الموافقة على الإجازة بنجاح');
      }
    } catch (e) {
      print('خطأ: $e');
    }
  }

  Future<void> rejectLeave(int leaveId, String reason) async {
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
  }
}
```

### Example 3: Stock Picking Workflow

```dart
class StockPickingService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> processPickingWorkflow(int pickingId) async {
    try {
      OdooContext.setDefault(
        lang: 'ar_001',
        timezone: 'Asia/Riyadh',
      );

      // 1. Check availability
      final assignResult = await odoo.custom.actionAssign(
        model: 'stock.picking',
        ids: [pickingId],
      );

      if (!assignResult.success) {
        throw Exception('المنتجات غير متوفرة');
      }

      // 2. Validate transfer
      final validateResult = await odoo.custom.actionValidate(
        model: 'stock.picking',
        ids: [pickingId],
      );

      if (validateResult.success) {
        print('تم التحويل بنجاح');

        // Check for backorder
        if (validateResult.isAction) {
          final action = ActionResult.fromJson(validateResult.action!);
          if (action.resModel == 'stock.backorder.confirmation') {
            print('يوجد كمية متبقية - تم إنشاء backorder');
          }
        }
      }
    } catch (e) {
      print('خطأ: $e');
    }
  }
}
```

## 🚨 Error Handling

```dart
try {
  final result = await odoo.custom.callMethod(...);

  if (result.success) {
    // Success
    print('Result: ${result.result}');
  } else {
    // Error with details
    print('Error: ${result.error}');
    print('Code: ${result.errorDetails?['code']}');
    print('Data: ${result.errorDetails?['data']}');
  }
} on PaymentRequiredException catch (e) {
  print('Trial expired: ${e.message}');
} on AccountDeletedException catch (e) {
  print('Account deleted: ${e.message}');
} on UnauthorizedException catch (e) {
  print('Unauthorized: ${e.message}');
} on TenantSuspendedException catch (e) {
  print('Account suspended: ${e.message}');
} on ValidationException catch (e) {
  print('Validation error: ${e.message}');
} on NetworkException catch (e) {
  print('No internet: ${e.message}');
} on BridgeCoreException catch (e) {
  print('Error: ${e.message}');
}
```

## 📋 API Summary

### Odoo 18 New Features

| Feature | Description |
|---------|-------------|
| `OdooContext` | Global context manager |
| `callKw()` | Generic RPC caller |
| `actionValidate()` | Validate records |
| `actionDone()` | Mark as done |
| `actionApprove()` | Approve records |
| `actionReject()` | Reject records |
| `actionAssign()` | Assign records |
| `actionUnlock()` | Unlock documents |
| `executeButtonAction()` | Execute any button |
| `ActionResult` | Parse action responses |

### All Operations (33 Total)

**CRUD Operations:**
- create, read, update, delete
- search, searchRead, searchCount

**Batch Operations:**
- batchCreate, batchUpdate, batchDelete, executeBatch

**Web Operations (Odoo 14+):**
- webSearchRead, webRead, webSave

**Advanced Operations:**
- onchange, readGroup, defaultGet, copy, fieldsGet

**View Operations:**
- fieldsViewGet, getView, loadViews, getViews

**Name Operations:**
- nameSearch, nameGet, nameCreate

**Permission Operations:**
- checkAccessRights, exists

**Custom Operations:**
- callMethod, callKw
- actionConfirm, actionCancel, actionDraft, actionPost
- actionValidate, actionDone, actionApprove, actionReject
- actionAssign, actionUnlock, executeButtonAction

## 📚 Documentation

- **[Odoo 18 Guide](ODOO_18_GUIDE.md)** - Complete Odoo 18 integration guide
- **[Changelog v2.1.0](CHANGELOG_v2.1.0.md)** - What's new in v2.1.0
- **[API Reference](https://github.com/your-repo)** - Full API documentation

## ⚡ Best Practices for Odoo 18

### 1. Always Set Context

```dart
OdooContext.setDefault(
  lang: 'ar_001',
  timezone: 'Asia/Riyadh',
);
```

### 2. Handle Actions Properly

```dart
if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);
  // Handle the action
}
```

### 3. Check Warnings

```dart
if (result.hasWarnings) {
  for (var warning in result.warnings!) {
    showWarning(warning['message']);
  }
}
```

### 4. Use Appropriate Method

```dart
// For button actions
await odoo.custom.callMethod(model: '...', method: '...');

// For CRUD operations
await odoo.custom.callKw(model: '...', method: 'search_read', ...);

// For convenience
await odoo.custom.actionConfirm(model: '...', ids: [...]);
```

## 🔮 Compatibility

- **Odoo Versions:** 14, 15, 16, 17, 18
- **Flutter:** >=3.0.0
- **Dart:** >=3.0.0

## 📝 Migration from v2.0.x

No breaking changes! Just add context for better Odoo 18 support:

```dart
// Before (v2.0.x) - still works
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
);

// After (v2.1.0) - with Odoo 18 context
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'},
);
```

## 🤝 Support

For issues and questions:
- GitHub Issues: https://github.com/your-repo/issues
- Documentation: See ODOO_18_GUIDE.md

## 📄 License

MIT License

---

**Version:** 2.1.0
**Last Updated:** 2025-11-24
**Odoo Compatibility:** 14, 15, 16, 17, 18
