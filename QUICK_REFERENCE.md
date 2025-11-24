# BridgeCore Flutter SDK - Quick Reference

Quick reference guide for common Odoo 18 operations.

## 🚀 Setup

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// Initialize
BridgeCore.initialize(baseUrl: 'https://api.yourdomain.com');

// Set Arabic context
OdooContext.setDefault(
  lang: 'ar_001',
  timezone: 'Asia/Riyadh',
  allowedCompanyIds: [1],
);

// Login
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password',
);
```

---

## 📖 CRUD Operations

### Create

```dart
// Using callKw
final result = await odoo.custom.callKw(
  model: 'res.partner',
  method: 'create',
  args: [{'name': 'شركة جديدة', 'email': 'info@company.sa'}],
);
final newId = result.result as int;

// Using standard method
final id = await odoo.create(
  model: 'res.partner',
  values: {'name': 'شركة جديدة', 'email': 'info@company.sa'},
);
```

### Read

```dart
// Read specific records
final records = await odoo.read(
  model: 'res.partner',
  ids: [1, 2, 3],
  fields: ['name', 'email', 'phone'],
);

// Search and read
final partners = await odoo.searchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  fields: ['name', 'email'],
  limit: 50,
);
```

### Update

```dart
await odoo.update(
  model: 'res.partner',
  ids: [123],
  values: {'phone': '+966501234567'},
);
```

### Delete

```dart
await odoo.delete(
  model: 'res.partner',
  ids: [123],
);
```

---

## 🔍 Search Operations

```dart
// Search for IDs
final ids = await odoo.search(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  limit: 50,
);

// Count
final count = await odoo.searchCount(
  model: 'res.partner',
  domain: [['country_id.code', '=', 'SA']],
);

// Search and read with context
final partners = await odoo.searchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  fields: ['name', 'email'],
  limit: 50,
  // Context automatically applied from OdooContext
);
```

---

## ⚡ Action Methods

### Standard Actions

```dart
// Confirm
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

// Draft
await odoo.custom.actionDraft(
  model: 'sale.order',
  ids: [orderId],
);

// Post
await odoo.custom.actionPost(
  model: 'account.move',
  ids: [invoiceId],
);
```

### Odoo 18 New Actions

```dart
// Validate
await odoo.custom.actionValidate(
  model: 'stock.picking',
  ids: [pickingId],
);

// Done
await odoo.custom.actionDone(
  model: 'purchase.order',
  ids: [orderId],
);

// Approve
await odoo.custom.actionApprove(
  model: 'hr.leave',
  ids: [leaveId],
);

// Reject
await odoo.custom.actionReject(
  model: 'hr.leave',
  ids: [leaveId],
);

// Assign
await odoo.custom.actionAssign(
  model: 'stock.picking',
  ids: [pickingId],
);

// Unlock
await odoo.custom.actionUnlock(
  model: 'account.move',
  ids: [moveId],
);

// Execute any button
await odoo.custom.executeButtonAction(
  model: 'sale.order',
  buttonMethod: 'action_quotation_send',
  ids: [orderId],
);
```

---

## 🔧 Call Methods

### callMethod

```dart
final result = await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
  args: [arg1, arg2],
  kwargs: {'param': 'value'},
  context: {'lang': 'ar_001'},
);

if (result.success) {
  print(result.result);
  if (result.isAction) {
    // Handle action
  }
} else {
  print(result.error);
}
```

### callKw (Generic RPC)

```dart
final result = await odoo.custom.callKw(
  model: 'res.partner',
  method: 'search_read',
  args: [[['is_company', '=', true]]],
  kwargs: {
    'fields': ['name', 'email'],
    'limit': 10,
  },
  context: {'lang': 'ar_001'},
);
```

---

## 🎯 Context Management

```dart
// Set global context
OdooContext.setDefault(
  lang: 'ar_001',
  timezone: 'Asia/Riyadh',
  allowedCompanyIds: [1, 2],
);

// Update language
OdooContext.setLanguage('ar_001');

// Update timezone
OdooContext.setTimezone('Asia/Riyadh');

// Update companies
OdooContext.setAllowedCompanies([1, 2, 3]);

// Clear
OdooContext.clear();

// Override in call
await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
  context: {'lang': 'en_US'}, // Override default
);
```

---

## 🎨 Action Result Handling

```dart
final result = await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_view_invoice',
  ids: [orderId],
);

if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);

  if (action.isWindowAction) {
    if (action.isFormView) {
      // Navigate to form
      navigateTo(action.resModel!, action.resId!);
    } else if (action.isListView) {
      // Navigate to list
      navigateToList(action.resModel!, action.domain);
    }
  } else if (action.isReportAction) {
    downloadReport(action.reportName!);
  } else if (action.isUrlAction) {
    openUrl(action.url!);
  }
}
```

---

## 📊 Advanced Operations

### Onchange

```dart
final result = await odoo.advanced.onchange(
  model: 'sale.order.line',
  values: {
    'product_id': 5,
    'product_uom_qty': 2.0,
  },
  field: 'product_id',
  spec: {
    'product_id': '1',
    'price_unit': '1',
  },
);

print('Price: ${result.value?['price_unit']}');
```

### Read Group

```dart
final report = await odoo.advanced.readGroup(
  model: 'sale.order',
  domain: [['state', '=', 'sale']],
  fields: ['amount_total'],
  groupby: ['partner_id'],
);
```

### Check Permissions

```dart
final canDelete = await odoo.permissions.checkAccessRights(
  model: 'sale.order',
  operation: 'unlink',
);

if (canDelete.hasAccess!) {
  // Show delete button
}
```

---

## 🚨 Error Handling

```dart
try {
  final result = await odoo.custom.callMethod(...);

  if (!result.success) {
    print('Error: ${result.error}');
    print('Code: ${result.errorDetails?['code']}');
    print('Data: ${result.errorDetails?['data']}');
  }

  if (result.hasWarnings) {
    for (var warning in result.warnings!) {
      print('Warning: ${warning['message']}');
    }
  }
} on PaymentRequiredException {
  // Trial expired
} on TenantSuspendedException {
  // Account suspended
} on UnauthorizedException {
  // Invalid token
} on ValidationException {
  // Validation error
} on NetworkException {
  // No internet
} on BridgeCoreException catch (e) {
  print('Error: ${e.message}');
}
```

---

## 📦 Batch Operations

```dart
// Batch create
final ids = await odoo.batchCreate(
  model: 'res.partner',
  valuesList: [
    {'name': 'Company 1'},
    {'name': 'Company 2'},
  ],
);

// Batch update
await odoo.batchUpdate(
  model: 'res.partner',
  updates: [
    {'id': 1, 'values': {'phone': '+966501234567'}},
    {'id': 2, 'values': {'phone': '+966509876543'}},
  ],
);

// Batch delete
await odoo.batchDelete(
  model: 'res.partner',
  ids: [1, 2, 3],
);
```

---

## 💡 Common Patterns

### Sales Order Workflow

```dart
// 1. Create order
final orderId = await odoo.create(
  model: 'sale.order',
  values: {'partner_id': partnerId},
);

// 2. Add lines
await odoo.create(
  model: 'sale.order.line',
  values: {
    'order_id': orderId,
    'product_id': productId,
    'product_uom_qty': 2.0,
  },
);

// 3. Confirm
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
);
```

### HR Leave Approval

```dart
// 1. Check permission
final canApprove = await odoo.permissions.checkAccessRights(
  model: 'hr.leave',
  operation: 'write',
);

if (!canApprove.hasAccess!) {
  throw Exception('لا تملك صلاحية الموافقة');
}

// 2. Approve
await odoo.custom.actionApprove(
  model: 'hr.leave',
  ids: [leaveId],
  context: {'lang': 'ar_001'},
);
```

### Stock Transfer

```dart
// 1. Check availability
await odoo.custom.actionAssign(
  model: 'stock.picking',
  ids: [pickingId],
);

// 2. Validate
final result = await odoo.custom.actionValidate(
  model: 'stock.picking',
  ids: [pickingId],
);

// 3. Check for backorder
if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);
  if (action.resModel == 'stock.backorder.confirmation') {
    print('Backorder created');
  }
}
```

---

## 🔑 Context Keys Reference

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `lang` | String | Language code | `'ar_001'`, `'en_US'` |
| `tz` | String | Timezone | `'Asia/Riyadh'`, `'UTC'` |
| `allowed_company_ids` | List<int> | Multi-company | `[1, 2, 3]` |
| `uid` | int | User ID | `1` |
| `active_id` | int | Active record ID | `123` |
| `active_ids` | List<int> | Active record IDs | `[1, 2, 3]` |

---

## 📞 Quick Links

- **Full Documentation:** [ODOO_18_GUIDE.md](ODOO_18_GUIDE.md)
- **Changelog:** [CHANGELOG_v2.1.0.md](CHANGELOG_v2.1.0.md)
- **GitHub Issues:** https://github.com/your-repo/issues

---

**Version:** 2.1.0
**Odoo:** 14, 15, 16, 17, 18
