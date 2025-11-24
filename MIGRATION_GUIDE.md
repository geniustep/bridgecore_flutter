# Migration Guide - v2.0.x to v2.1.0

Complete guide for upgrading from BridgeCore Flutter SDK v2.0.x to v2.1.0.

## ✅ Good News - No Breaking Changes!

Version 2.1.0 is **100% backward compatible** with v2.0.x. Your existing code will continue to work without any modifications.

All new features are **additive** - they extend functionality without changing existing APIs.

---

## 📊 What's New

### New Features in v2.1.0

1. **OdooContext Manager** - Global context management
2. **callKw Method** - Generic RPC caller
3. **7 New Action Methods** - validate, done, approve, reject, assign, unlock, executeButtonAction
4. **Action Result Handler** - Parse window actions
5. **Enhanced Error Handling** - Detailed error information
6. **Context Parameter** - All methods now accept optional context

---

## 🚀 Migration Steps

### Step 1: Update Your Code (Optional)

While not required, we recommend updating your code to take advantage of new features:

#### Before (v2.0.x)

```dart
void main() {
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
  );
  runApp(MyApp());
}

// Using actions
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
);
```

#### After (v2.1.0) - Recommended

```dart
void main() {
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
  );

  // NEW: Set default Odoo 18 context
  OdooContext.setDefault(
    lang: 'ar_001',
    timezone: 'Asia/Riyadh',
    allowedCompanyIds: [1],
  );

  runApp(MyApp());
}

// Using actions with context
await odoo.custom.actionConfirm(
  model: 'sale.order',
  ids: [orderId],
  context: {'lang': 'ar_001'}, // NEW: Optional context
);
```

---

## 🔄 Feature-by-Feature Migration

### 1. Context Management (Recommended)

**Before:** No global context support

**After:** Set global context once

```dart
// Add after BridgeCore.initialize()
OdooContext.setDefault(
  lang: 'ar_001',              // Your language
  timezone: 'Asia/Riyadh',     // Your timezone
  allowedCompanyIds: [1, 2],   // Your companies
);
```

**Benefits:**
- ✅ Automatic language support in all operations
- ✅ Correct timezone handling
- ✅ Multi-company support
- ✅ No need to pass context in every call

---

### 2. Using New Action Methods (Optional)

**New methods available:**

```dart
// Validate (stock, inventory)
await odoo.custom.actionValidate(
  model: 'stock.picking',
  ids: [pickingId],
);

// Done (purchase, manufacturing)
await odoo.custom.actionDone(
  model: 'purchase.order',
  ids: [orderId],
);

// Approve (HR, expenses)
await odoo.custom.actionApprove(
  model: 'hr.leave',
  ids: [leaveId],
);

// Reject (approval workflows)
await odoo.custom.actionReject(
  model: 'hr.leave',
  ids: [leaveId],
);

// Assign (stock, tasks)
await odoo.custom.actionAssign(
  model: 'stock.picking',
  ids: [pickingId],
);

// Unlock (accounting)
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

**When to use:** Replace manual `callMethod` calls with these convenience methods.

---

### 3. Using callKw (Optional)

**Before:** Using callMethod for everything

```dart
final result = await odoo.custom.callMethod(
  model: 'res.partner',
  method: 'search_read',
  args: [[['is_company', '=', true]]],
  kwargs: {'fields': ['name', 'email']},
);
```

**After:** Use callKw for better Odoo compatibility

```dart
final result = await odoo.custom.callKw(
  model: 'res.partner',
  method: 'search_read',
  args: [[['is_company', '=', true]]],
  kwargs: {'fields': ['name', 'email']},
  context: {'lang': 'ar_001'},
);
```

**Benefits:**
- ✅ More compatible with Odoo's execute_kw pattern
- ✅ Cleaner separation of args, kwargs, and context

---

### 4. Action Result Handling (Recommended)

**Before:** Ignoring action results

```dart
final result = await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_view_invoice',
  ids: [orderId],
);
// Result might contain an action, but we don't handle it
```

**After:** Handle action results properly

```dart
final result = await odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_view_invoice',
  ids: [orderId],
);

if (result.isAction) {
  final action = ActionResult.fromJson(result.action!);

  if (action.isWindowAction && action.isFormView) {
    // Navigate to invoice form
    navigateToInvoice(action.resId!);
  } else if (action.isReportAction) {
    // Download report
    downloadReport(action.reportName!);
  }
}
```

**Benefits:**
- ✅ Handle wizards properly
- ✅ Navigate to forms/lists returned by actions
- ✅ Download reports automatically
- ✅ Open URLs when needed

---

### 5. Enhanced Error Handling (Recommended)

**Before:** Basic error handling

```dart
final result = await odoo.custom.callMethod(...);

if (!result.success) {
  print('Error: ${result.error}');
}
```

**After:** Detailed error information

```dart
final result = await odoo.custom.callMethod(...);

if (!result.success) {
  print('Error: ${result.error}');
  print('Error code: ${result.errorDetails?['code']}');
  print('Error data: ${result.errorDetails?['data']}');
}

// Check for warnings
if (result.hasWarnings) {
  for (var warning in result.warnings!) {
    showWarning(warning['message']);
  }
}
```

**Benefits:**
- ✅ Better error debugging
- ✅ Show warnings to users
- ✅ Access error codes and data

---

## 📝 Migration Checklist

Use this checklist to upgrade your app:

### Required (None - Backward Compatible)
- [ ] No required changes - your code works as-is!

### Recommended
- [ ] Add `OdooContext.setDefault()` after initialization
- [ ] Update action calls to include `context` parameter
- [ ] Handle action results with `ActionResult`
- [ ] Check for warnings with `result.hasWarnings`
- [ ] Use detailed error info from `result.errorDetails`

### Optional
- [ ] Replace `callMethod` with `callKw` for CRUD operations
- [ ] Use new action methods (`actionValidate`, `actionApprove`, etc.)
- [ ] Add context-aware features (language switching, timezone)

---

## 🎯 Use Case Examples

### Example 1: Sales Order App

**Before (v2.0.x):**

```dart
class SalesOrderService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> confirmOrder(int orderId) async {
    await odoo.custom.actionConfirm(
      model: 'sale.order',
      ids: [orderId],
    );
  }
}
```

**After (v2.1.0):**

```dart
class SalesOrderService {
  final odoo = BridgeCore.instance.odoo;

  Future<void> confirmOrder(int orderId) async {
    final result = await odoo.custom.actionConfirm(
      model: 'sale.order',
      ids: [orderId],
      context: {'lang': 'ar_001'}, // NEW
    );

    // NEW: Handle action results
    if (result.isAction) {
      final action = ActionResult.fromJson(result.action!);
      if (action.isFormView) {
        navigateToOrder(action.resId!);
      }
    }

    // NEW: Check warnings
    if (result.hasWarnings) {
      showWarnings(result.warnings!);
    }
  }
}
```

---

### Example 2: HR Leave App

**Before (v2.0.x):**

```dart
Future<void> approveLeave(int leaveId) async {
  final result = await odoo.custom.callMethod(
    model: 'hr.leave',
    method: 'action_approve',
    ids: [leaveId],
  );
}
```

**After (v2.1.0):**

```dart
Future<void> approveLeave(int leaveId) async {
  // NEW: Use convenience method
  final result = await odoo.custom.actionApprove(
    model: 'hr.leave',
    ids: [leaveId],
    context: {'lang': 'ar_001'},
  );

  if (!result.success) {
    // NEW: Show detailed error
    print('Error: ${result.error}');
    print('Code: ${result.errorDetails?['code']}');
  }
}
```

---

### Example 3: Stock Management

**Before (v2.0.x):**

```dart
Future<void> validatePicking(int pickingId) async {
  final result = await odoo.custom.callMethod(
    model: 'stock.picking',
    method: 'button_validate',
    ids: [pickingId],
  );
}
```

**After (v2.1.0):**

```dart
Future<void> validatePicking(int pickingId) async {
  // 1. Check availability first
  await odoo.custom.actionAssign(
    model: 'stock.picking',
    ids: [pickingId],
  );

  // 2. Validate with proper method
  final result = await odoo.custom.actionValidate(
    model: 'stock.picking',
    ids: [pickingId],
    context: {'lang': 'ar_001'},
  );

  // 3. Handle backorder wizard if needed
  if (result.isAction) {
    final action = ActionResult.fromJson(result.action!);
    if (action.resModel == 'stock.backorder.confirmation') {
      // Show backorder dialog to user
      showBackorderDialog(action);
    }
  }
}
```

---

## 🔍 Testing Your Migration

### 1. Test Context

```dart
void testContext() async {
  // Set context
  OdooContext.setDefault(lang: 'ar_001');

  // Verify it's applied
  final result = await odoo.searchRead(
    model: 'res.partner',
    fields: ['name'],
    limit: 1,
  );

  // Check if Arabic names are returned
  print(result.first['name']); // Should show Arabic if available
}
```

### 2. Test Action Methods

```dart
void testActionMethods() async {
  // Test each new action
  try {
    await odoo.custom.actionValidate(
      model: 'stock.picking',
      ids: [testPickingId],
    );
    print('✅ actionValidate works');

    await odoo.custom.actionApprove(
      model: 'hr.leave',
      ids: [testLeaveId],
    );
    print('✅ actionApprove works');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### 3. Test Error Handling

```dart
void testErrorHandling() async {
  final result = await odoo.custom.callMethod(
    model: 'sale.order',
    method: 'invalid_method',
    ids: [1],
  );

  if (!result.success) {
    print('Error: ${result.error}');
    print('Code: ${result.errorDetails?['code']}');
    print('Data: ${result.errorDetails?['data']}');
  }
}
```

---

## 🚨 Common Issues & Solutions

### Issue 1: Context Not Applied

**Problem:** Language/timezone not working

**Solution:**
```dart
// Make sure to set context after initialization
BridgeCore.initialize(...);
OdooContext.setDefault(lang: 'ar_001', timezone: 'Asia/Riyadh');
```

---

### Issue 2: Action Not Recognized

**Problem:** New action methods not found

**Solution:**
```dart
// Make sure you're importing the updated package
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// Check that you're on v2.1.0
// pubspec.yaml should reference v2.1.0
```

---

### Issue 3: callKw Not Available

**Problem:** `callKw` method not found

**Solution:**
```dart
// Import the package
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// Access via custom operations
final result = await BridgeCore.instance.odoo.custom.callKw(...);
```

---

## 📊 Performance Considerations

### Context Caching

```dart
// Setting context once is more efficient
OdooContext.setDefault(lang: 'ar_001');

// Than passing it every time
await odoo.custom.callMethod(..., context: {'lang': 'ar_001'});
await odoo.custom.callMethod(..., context: {'lang': 'ar_001'});
await odoo.custom.callMethod(..., context: {'lang': 'ar_001'});
```

### Use Convenience Methods

```dart
// More efficient
await odoo.custom.actionConfirm(...);

// Than manual callMethod
await odoo.custom.callMethod(
  model: '...',
  method: 'action_confirm',
  ids: [...],
);
```

---

## 🎓 Learning Resources

### Documentation
- **[README.md](README.md)** - Main documentation
- **[ODOO_18_GUIDE.md](ODOO_18_GUIDE.md)** - Complete Odoo 18 guide
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference
- **[CHANGELOG_v2.1.0.md](CHANGELOG_v2.1.0.md)** - Detailed changelog

### Examples
- Sales Order workflow in README.md
- HR Leave approval in ODOO_18_GUIDE.md
- Stock Picking in QUICK_REFERENCE.md

---

## 🤝 Getting Help

If you encounter issues during migration:

1. Check this migration guide
2. Read ODOO_18_GUIDE.md for detailed examples
3. Review QUICK_REFERENCE.md for syntax
4. Open an issue on GitHub

---

## ✅ Migration Completed!

Once you've:
- [ ] Updated your code (optional but recommended)
- [ ] Added context management
- [ ] Tested your app
- [ ] Verified error handling

You're ready to enjoy all the new Odoo 18 features! 🎉

---

**Version:** 2.1.0
**Last Updated:** 2025-11-24
**Compatibility:** Fully backward compatible with v2.0.x
