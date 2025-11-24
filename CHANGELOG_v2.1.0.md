# Changelog v2.1.0 - Odoo 18 Support

## 🚀 Major Updates

### Odoo 18 Full Support

Complete integration with Odoo 18 features including context management, enhanced error handling, and comprehensive action methods.

---

## ✨ New Features

### 1. Context Management (Odoo 18)

- **OdooContext Manager** - Global context management for language, timezone, and company
- **Automatic Context Merging** - Default context automatically merged with call-specific context
- **Multi-Company Support** - Full support for `allowed_company_ids` context parameter

```dart
// Set default context
OdooContext.setDefault(
  lang: 'ar_001',
  timezone: 'Asia/Riyadh',
  allowedCompanyIds: [1, 2],
);
```

### 2. callKw - Generic RPC Caller

New `callKw` method for full compatibility with Odoo's execute_kw pattern.

```dart
final result = await BridgeCore.instance.odoo.custom.callKw(
  model: 'res.partner',
  method: 'search_read',
  args: [[['is_company', '=', true]]],
  kwargs: {'fields': ['name', 'email']},
  context: {'lang': 'ar_001'},
);
```

### 3. Seven New Action Methods

- ✅ `actionValidate` - Validate records (stock pickings, inventory)
- ✅ `actionDone` - Mark as done (purchase orders, manufacturing)
- ✅ `actionApprove` - Approve records (HR leaves, expenses)
- ✅ `actionReject` - Reject/refuse records (approval workflows)
- ✅ `actionAssign` - Assign records (stock picking, tasks)
- ✅ `actionUnlock` - Unlock posted documents (accounting)
- ✅ `executeButtonAction` - Execute any button action by name

```dart
// Validate stock picking
await odoo.custom.actionValidate(
  model: 'stock.picking',
  ids: [pickingId],
  context: {'lang': 'ar_001'},
);

// Approve HR leave
await odoo.custom.actionApprove(
  model: 'hr.leave',
  ids: [leaveId],
  context: {'lang': 'ar_001'},
);
```

### 4. Enhanced Response Models

- **Action Detection** - Automatically detect window actions in responses
- **Warnings Support** - Handle warnings returned by Odoo
- **Detailed Error Info** - Enhanced error details with code and data

```dart
final result = await odoo.custom.callMethod(...);

// Check for action
if (result.isAction) {
  print('Action: ${result.action}');
}

// Check for warnings
if (result.hasWarnings) {
  print('Warnings: ${result.warnings}');
}

// Detailed error info
if (!result.success) {
  print('Error: ${result.error}');
  print('Code: ${result.errorDetails?['code']}');
}
```

### 5. ActionResult Handler

New `ActionResult` class to parse and handle Odoo action dictionaries.

```dart
if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);

  print('Type: ${action.type}');
  print('Model: ${action.resModel}');
  print('View: ${action.viewMode}');

  if (action.isWindowAction) {
    // Handle window action
  } else if (action.isReportAction) {
    // Handle report
  }
}
```

---

## 🔧 Improvements

### Context Parameter Added to All Methods

All existing action methods now support context parameter:

```dart
// Before
await odoo.custom.actionConfirm(model: 'sale.order', ids: [1]);

// After (backward compatible)
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [1],
  context: {'lang': 'ar_001'},
);
```

### Enhanced Error Handling

- Error messages now include detailed information from Odoo 18
- Error codes and data are preserved in `errorDetails`
- Better error messages for validation failures

### Request/Response Models Updated

- `CallMethodRequest` - Added context parameter
- `CallMethodResponse` - Added action, warnings, and errorDetails
- `CallKwRequest` - New model for callKw
- `CallKwResponse` - New response model for callKw

---

## 📦 New Classes & Files

### Core Classes

1. **OdooContext** (`lib/src/odoo/odoo_context.dart`)
   - Global context manager
   - Methods: `setDefault`, `merge`, `clear`, `update`

2. **ActionResult** (`lib/src/odoo/models/action_result.dart`)
   - Parse and handle Odoo actions
   - Helper methods: `isWindowAction`, `isFormView`, etc.

3. **CallKwRequest** (`lib/src/odoo/models/request/call_kw_request.dart`)
   - Request model for callKw

4. **CallKwResponse** (`lib/src/odoo/models/response/call_kw_response.dart`)
   - Response model for callKw

### Updated Classes

1. **CustomOperations** (`lib/src/odoo/operations/custom_operations.dart`)
   - Added 7 new action methods
   - Added `callKw` method
   - Updated all existing methods with context support

2. **CallMethodRequest** (`lib/src/odoo/models/request/call_method_request.dart`)
   - Added `context` parameter

3. **CallMethodResponse** (`lib/src/odoo/models/response/call_method_response.dart`)
   - Added `action`, `warnings`, `errorDetails`
   - Added helper getters: `isAction`, `hasWarnings`

---

## 📚 Documentation

### New Documentation Files

1. **ODOO_18_GUIDE.md** - Comprehensive Odoo 18 integration guide
   - Context management guide
   - Call methods comparison
   - Action methods reference
   - Complete examples (Sales, HR, Stock)
   - Best practices
   - Troubleshooting

2. **CHANGELOG_v2.1.0.md** - This file

### Updated Documentation

- README.md will be updated with Odoo 18 section
- All method examples now include context parameter

---

## 🧪 Testing

### New Test File

- `test/custom_operations_test.dart` - Comprehensive tests for:
  - callMethod with context
  - callKw functionality
  - All action methods
  - Context merging
  - Error handling
  - Action result parsing
  - OdooContext manager

---

## 📋 Breaking Changes

### ⚠️ None - Fully Backward Compatible

All changes are **backward compatible**. Existing code will continue to work without modifications.

The `context` parameter is optional in all methods.

---

## 🔄 Migration Guide

### From v2.0.x to v2.1.0

No breaking changes. Optionally add context for better Odoo 18 support:

```dart
// Optional: Set default context
OdooContext.setDefault(
  lang: 'ar_001',
  timezone: 'Asia/Riyadh',
);

// Optional: Add context to calls
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'}, // Optional
);
```

---

## 📊 API Changes Summary

### New Methods

| Method | Description |
|--------|-------------|
| `callKw` | Generic RPC caller (execute_kw compatible) |
| `actionValidate` | Validate records |
| `actionDone` | Mark as done |
| `actionApprove` | Approve records |
| `actionReject` | Reject/refuse records |
| `actionAssign` | Assign records |
| `actionUnlock` | Unlock posted documents |
| `executeButtonAction` | Execute any button by name |

### Updated Methods

All existing action methods now accept optional `context` parameter:
- `callMethod`
- `actionConfirm`
- `actionCancel`
- `actionDraft`
- `actionPost`

### New Classes

- `OdooContext`
- `ActionResult`
- `CallKwRequest`
- `CallKwResponse`

---

## 🎯 Use Cases

### Perfect for:

- ✅ Arabic/RTL applications
- ✅ Multi-company Odoo instances
- ✅ Custom Odoo workflows
- ✅ HR management apps
- ✅ Stock/Inventory management
- ✅ Accounting integrations
- ✅ Any Odoo 18 integration

---

## 🔮 Future Plans

- REST API support (for Odoo 20+ when RPC is deprecated)
- Wizard helper classes
- Batch action operations
- Action result navigation helpers

---

## 📝 Notes

### Odoo 18 Compatibility

This SDK is fully compatible with Odoo 18. All features follow Odoo 18 conventions and best practices.

### RPC Deprecation Notice

Odoo will deprecate XML-RPC and JSON-RPC in Odoo 20 (fall 2026). We will add REST API support before that date.

---

## 🙏 Credits

Developed for Odoo 18 integration with full Arabic support.

---

**Release Date:** 2025-11-24
**Version:** 2.1.0
**Odoo Compatibility:** 14, 15, 16, 17, 18
