# BridgeCore Flutter SDK v2.0.0

Official Flutter SDK for BridgeCore API - Complete Odoo integration with 26 operations.

## 🎉 What's New in v2.0.0

- ✅ **100% Operation Coverage** - All 26 Odoo operations implemented
- ✅ **9 New Operations** - onchange, readGroup, checkAccessRights, and more
- ✅ **Modular Architecture** - Clean separation with operation classes
- ✅ **Full Type Safety** - All operations with typed request/response models

## ✨ Features

### Core Features
- ✅ **Easy Authentication** - Login, refresh, logout with automatic token management
- ✅ **26 Odoo Operations** - Complete CRUD, search, advanced, views, permissions, and custom operations
- ✅ **Auto Token Refresh** - Automatic token refresh on expiry
- ✅ **Comprehensive Exceptions** - 10 specialized exception types
- ✅ **Null Safety** - Full null safety support
- ✅ **Type Safe** - Strongly typed models and responses

### Advanced Features
- ✅ **Onchange Support** 🆕 - Auto-calculate field values (critical for forms)
- ✅ **Read Group** 🆕 - Aggregate data for reports and analytics
- ✅ **Permission Checking** 🆕 - Check user access rights
- ✅ **View Operations** 🆕 - Load view definitions dynamically
- ✅ **Custom Methods** 🆕 - Call any Odoo method
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

### 1. Initialize

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
    debugMode: true, // Enable debug logs
    enableCache: true, // Enable caching
    enableLogging: true, // Enable logging
    logLevel: LogLevel.info,
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
  // Trial period expired
  print('Please upgrade your account');
} on TenantSuspendedException catch (e) {
  // Account suspended
  print('Account suspended: ${e.message}');
} on UnauthorizedException catch (e) {
  // Invalid credentials
  print('Login failed: ${e.message}');
}
```

### 2.1. Get User Info with Custom Odoo Fields

```dart
// Get basic user info (cached for 5 minutes)
final userInfo = await BridgeCore.instance.auth.me();
print('Partner ID: ${userInfo.partnerId}');
print('Is Admin: ${userInfo.isAdmin}');
print('Groups: ${userInfo.groups}');

// Get user info with custom Odoo fields
final userWithFields = await BridgeCore.instance.auth.me(
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['shuttle_role', 'phone', 'mobile'],
  ),
  forceRefresh: true, // Bypass cache
);

// Access custom fields
print('Shuttle Role: ${userWithFields.odooFieldsData?['shuttle_role']}');
print('Phone: ${userWithFields.odooFieldsData?['phone']}');

// Check permissions
if (userWithFields.hasGroup('shuttlebee.group_shuttle_driver')) {
  print('User is a driver');
}
```

### 3. Use Odoo Operations

```dart
// Basic Operations
final partners = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  fields: ['name', 'email', 'phone'],
  limit: 50,
);

// NEW: Onchange (auto-calculate values)
final result = await BridgeCore.instance.odoo.advanced.onchange(
  model: 'sale.order.line',
  values: {'product_id': 5, 'product_uom_qty': 2.0},
  field: 'product_id',
  spec: {'product_id': '1', 'price_unit': '1'},
);
print('Calculated price: ${result.value?['price_unit']}');

// NEW: Read Group (reports)
final report = await BridgeCore.instance.odoo.advanced.readGroup(
  model: 'sale.order',
  domain: [['state', '=', 'sale']],
  fields: ['amount_total'],
  groupby: ['partner_id'],
);

// NEW: Check Permissions
final canDelete = await BridgeCore.instance.odoo.permissions.checkAccessRights(
  model: 'sale.order',
  operation: 'unlink',
);
if (canDelete.hasAccess!) {
  // Show delete button
}
```

## 📚 API Reference

### Authentication

```dart
// Basic Login
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password123',
);

// Login with Odoo Fields Check 🆕
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password123',
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code', 'x_department', 'x_branch_id'],
  ),
);

// Check custom fields result
if (session.odooFieldsData?.success == true) {
  final customData = session.odooFieldsData!.data;
  print('Employee Code: ${customData?['x_employee_code']}');
  print('Department: ${customData?['x_department']}');
}

// Get Current User Info 🆕
final userInfo = await BridgeCore.instance.auth.me();
print('Partner ID: ${userInfo.partnerId}');
print('Is Admin: ${userInfo.isAdmin}');
print('Groups: ${userInfo.groups}');

// Get User Info with Custom Fields 🆕
final userInfoWithFields = await BridgeCore.instance.auth.me(
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['phone', 'mobile', 'signature'],
  ),
);
print('Phone: ${userInfoWithFields.odooFieldsData?['phone']}');

// Check Permissions 🆕
if (userInfo.canManagePartners) {
  print('User can manage partners');
}

if (userInfo.hasGroup('base.group_system')) {
  print('User is system administrator');
}

// Logout
await BridgeCore.instance.auth.logout();

// Check if logged in
if (await BridgeCore.instance.auth.isLoggedIn) {
  // User is logged in
}
```

### User Information & Permissions 🆕

The `/me` endpoint provides comprehensive user information including permissions and Odoo integration:

```dart
// Get detailed user information
final userInfo = await BridgeCore.instance.auth.me();

// User Profile
print('Name: ${userInfo.user.fullName}');
print('Email: ${userInfo.user.email}');
print('Role: ${userInfo.user.role}');

// Odoo Integration
print('Partner ID: ${userInfo.partnerId}');
print('Employee ID: ${userInfo.employeeId}');
print('Is Admin: ${userInfo.isAdmin}');
print('Is Employee: ${userInfo.isEmployee}');

// Permissions & Groups
print('Groups: ${userInfo.groups}');
print('Can Manage Partners: ${userInfo.canManagePartners}');
print('Has Multi-Company Access: ${userInfo.hasMultiCompanyAccess}');

// Check specific group
if (userInfo.hasGroup('base.group_system')) {
  print('User is system administrator');
}

// Check multiple groups
if (userInfo.hasAnyGroup(['sale.group_sale_manager', 'base.group_erp_manager'])) {
  print('User can manage sales or is ERP manager');
}

// Multi-Company
if (userInfo.isMultiCompany) {
  print('User has access to ${userInfo.companyIds.length} companies');
  print('Current company: ${userInfo.currentCompanyId}');
}

// With custom Odoo fields
final userInfoWithFields = await BridgeCore.instance.auth.me(
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['phone', 'mobile', 'x_employee_code'],
  ),
);

final customData = userInfoWithFields.odooFieldsData;
print('Phone: ${customData?['phone']}');
print('Employee Code: ${customData?['x_employee_code']}');

// Force refresh (bypass 5-minute cache)
final freshInfo = await BridgeCore.instance.auth.me(forceRefresh: true);
```

**See [ME_ENDPOINT.md](ME_ENDPOINT.md) for complete documentation.**

### Odoo Operations (26 Total)

#### CRUD Operations
```dart
// Create
final id = await BridgeCore.instance.odoo.create(
  model: 'res.partner',
  values: {'name': 'New Company', 'email': 'info@company.com'},
);

// Read
final records = await BridgeCore.instance.odoo.read(
  model: 'res.partner',
  ids: [1, 2, 3],
  fields: ['name', 'email'],
);

// Update
await BridgeCore.instance.odoo.update(
  model: 'res.partner',
  ids: [123],
  values: {'phone': '+966501234567'},
);

// Delete
await BridgeCore.instance.odoo.delete(
  model: 'res.partner',
  ids: [123],
);

// Copy 🆕
final newId = await BridgeCore.instance.odoo.advanced.copy(
  model: 'product.template',
  id: 123,
  defaultValues: {'name': 'Copy of Product'},
);
```

#### Search Operations
```dart
// Search
final ids = await BridgeCore.instance.odoo.search(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  limit: 50,
);

// Search and Read
final records = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  fields: ['name', 'email'],
);

// Count
final count = await BridgeCore.instance.odoo.searchCount(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
);
```

#### Advanced Operations 🆕
```dart
// Onchange - Auto-calculate values
final result = await BridgeCore.instance.odoo.advanced.onchange(
  model: 'sale.order.line',
  values: {'product_id': 5, 'product_uom_qty': 2.0},
  field: 'product_id',
  spec: {'product_id': '1', 'price_unit': '1', 'discount': '1'},
);
print('Price: ${result.value?['price_unit']}');
print('Discount: ${result.value?['discount']}');

// Read Group - Reports and analytics
final report = await BridgeCore.instance.odoo.advanced.readGroup(
  model: 'sale.order',
  domain: [['state', '=', 'sale']],
  fields: ['amount_total'],
  groupby: ['partner_id'],
  orderby: 'amount_total desc',
  limit: 10,
);

// Default Get - Get default field values
final defaults = await BridgeCore.instance.odoo.advanced.defaultGet(
  model: 'sale.order',
  fields: ['partner_id', 'date_order', 'pricelist_id'],
);
```

#### View Operations 🆕
```dart
// Get view definition (Odoo ≤15)
final view = await BridgeCore.instance.odoo.views.fieldsViewGet(
  model: 'res.partner',
  viewType: 'form',
);

// Get view definition (Odoo 16+)
final view = await BridgeCore.instance.odoo.views.getView(
  model: 'res.partner',
  viewType: 'form',
);

// Load multiple views
final views = await BridgeCore.instance.odoo.views.getViews(
  model: 'res.partner',
  views: [[null, 'form'], [null, 'list']],
);
```

#### Name Operations
```dart
// Name Search
final results = await BridgeCore.instance.odoo.names.nameSearch(
  model: 'res.partner',
  name: 'Company',
  limit: 10,
);

// Name Get
final names = await BridgeCore.instance.odoo.names.nameGet(
  model: 'res.partner',
  ids: [1, 2, 3],
);

// Name Create 🆕
final record = await BridgeCore.instance.odoo.names.nameCreate(
  model: 'res.partner',
  name: 'New Customer',
);
print('Created ID: ${record.id}');
```

#### Permission Operations 🆕
```dart
// Check Access Rights
final canDelete = await BridgeCore.instance.odoo.permissions.checkAccessRights(
  model: 'sale.order',
  operation: 'unlink',
);
if (canDelete.hasAccess!) {
  // Show delete button
}

// Check if records exist
final existing = await BridgeCore.instance.odoo.permissions.exists(
  model: 'res.partner',
  ids: [1, 2, 999, 1000],
);
print('Existing IDs: ${existing.existingIds}'); // [1, 2]
```

#### Custom Methods 🆕
```dart
// Call any custom method
await BridgeCore.instance.odoo.custom.callMethod(
  model: 'sale.order',
  method: 'action_confirm',
  ids: [orderId],
);

// Convenience methods
await BridgeCore.instance.odoo.custom.actionConfirm(model: 'sale.order', ids: [orderId]);
await BridgeCore.instance.odoo.custom.actionCancel(model: 'sale.order', ids: [orderId]);
await BridgeCore.instance.odoo.custom.actionDraft(model: 'sale.order', ids: [orderId]);
await BridgeCore.instance.odoo.custom.actionPost(model: 'account.move', ids: [invoiceId]);
```

### Batch Operations

```dart
// Batch Create
final ids = await BridgeCore.instance.odoo.batchCreate(
  model: 'res.partner',
  valuesList: [
    {'name': 'Company 1', 'is_company': true},
    {'name': 'Company 2', 'is_company': true},
  ],
);

// Batch Update
await BridgeCore.instance.odoo.batchUpdate(
  model: 'res.partner',
  updates: [
    {'id': 1, 'values': {'phone': '+966501234567'}},
    {'id': 2, 'values': {'phone': '+966509876543'}},
  ],
);

// Batch Delete
await BridgeCore.instance.odoo.batchDelete(
  model: 'res.partner',
  ids: [1, 2, 3, 4, 5],
);

// Execute Batch
final results = await BridgeCore.instance.odoo.executeBatch([
  {'method': 'search_read', 'model': 'res.partner', 'domain': []},
  {'method': 'search_count', 'model': 'product.product', 'domain': []},
]);
```

### Web Operations (Odoo 14+)

```dart
// Web Search Read
final records = await BridgeCore.instance.odoo.webSearchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  fields: ['name', 'email'],
);

// Web Read
final records = await BridgeCore.instance.odoo.webRead(
  model: 'res.partner',
  ids: [1, 2, 3],
  fields: ['name', 'email'],
);

// Web Save
await BridgeCore.instance.odoo.webSave(
  model: 'res.partner',
  records: [
    {'id': 1, 'name': 'Updated Name'},
    {'id': 0, 'name': 'New Record'},
  ],
);
```

## 🚨 Error Handling

```dart
try {
  final partners = await BridgeCore.instance.odoo.searchRead(
    model: 'res.partner',
    fields: ['name'],
  );
} on PaymentRequiredException catch (e) {
  // 402 - Trial period expired 🆕
  print('Trial expired: ${e.message}');
  // Show upgrade screen
} on AccountDeletedException catch (e) {
  // 410 - Account deleted 🆕
  print('Account deleted: ${e.message}');
  // Show account deleted message
} on UnauthorizedException catch (e) {
  // 401 - Token expired
  print('Token expired: ${e.message}');
  print('Endpoint: ${e.endpoint}');
  print('Details: ${e.details}');
  // Redirect to login
} on TenantSuspendedException catch (e) {
  // 403 - Tenant suspended
  print('Account suspended: ${e.message}');
  // Show message to user
} on ValidationException catch (e) {
  // 400 - Bad request
  print('Validation error: ${e.message}');
  print('Details: ${e.details}');
} on NetworkException catch (e) {
  // Network error
  print('No internet: ${e.message}');
} on BridgeCoreException catch (e) {
  // Generic error
  print('Error: ${e.message}');
  print('Status: ${e.statusCode}');
  print('Endpoint: ${e.endpoint}');
  print('Timestamp: ${e.timestamp}');
}
```

### Exception Types:

```dart
UnauthorizedException        // 401 - Invalid or expired token
PaymentRequiredException     // 402 - Trial period expired 🆕
ForbiddenException          // 403 - No permission
TenantSuspendedException    // 403 - Tenant account suspended
NotFoundException           // 404 - Resource not found
AccountDeletedException      // 410 - Account deleted 🆕
ValidationException         // 400 - Validation error
NetworkException            // Network connectivity issues
ServerException             // 500+ - Server errors
BridgeCoreException         // Base exception with full details
```

## 🎯 Advanced Features

### 1. Odoo Fields Check 🆕

Verify custom fields in Odoo during login and fetch their values:

```dart
// Login with fields check
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password123',
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code', 'x_department', 'x_branch_id'],
  ),
);

// Check if fields exist and get their values
if (session.odooFieldsData?.success == true) {
  final fieldsData = session.odooFieldsData!;
  
  // Check if all fields exist
  if (fieldsData.fieldsExist) {
    print('All custom fields exist! ✅');
    
    // Get field information
    fieldsData.fieldsInfo?.forEach((fieldName, fieldInfo) {
      print('Field: ${fieldInfo.name}');
      print('Type: ${fieldInfo.ttype}');
      print('Description: ${fieldInfo.fieldDescription}');
    });
    
    // Get actual data
    final customData = fieldsData.data;
    print('Employee Code: ${customData?['x_employee_code']}');
    print('Department: ${customData?['x_department']}');
    print('Branch ID: ${customData?['x_branch_id']}');
  } else {
    print('Some fields are missing ⚠️');
    print('Error: ${fieldsData.error}');
  }
}
```

**Use Cases:**
- ✅ Verify employee codes before allowing login
- ✅ Check if custom fields exist in specific Odoo version
- ✅ Fetch user department/branch information
- ✅ Validate custom field configuration

### 2. Field Presets

Use predefined field lists for common models:

```dart
// Example 1: Using preset
final partners = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  domain: [['is_company', '=', true]],
  preset: FieldPreset.standard, // ← Use predefined fields
  limit: 50,
);

// Example 2: Custom fields (no preset)
final partners = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  domain: [],
  fields: ['name', 'email', 'phone'], // ← Custom fields
  limit: 50,
);

// Example 3: Fetch all fields
final partners = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  domain: [],
  preset: FieldPreset.all, // ← Fetch all from server
  limit: 50,
);
```

#### Available Presets:

```dart
FieldPreset.minimal   // id, name, display_name
FieldPreset.basic     // + create_date, write_date
FieldPreset.standard  // + create_uid, write_uid
FieldPreset.extended  // More fields (model-specific)
FieldPreset.all       // Everything
```

#### Add Custom Preset:

```dart
// Define custom preset for your model
FieldPresetsManager.addCustomPreset(
  'product.product',
  FieldPreset.standard,
  ['id', 'name', 'default_code', 'list_price', 'qty_available'],
);

// Use it
final products = await BridgeCore.instance.odoo.searchRead(
  model: 'product.product',
  preset: FieldPreset.standard,
);
```

### 3. Smart Field Fallback (Automatic Error Recovery)

Automatically retry requests when invalid fields are detected:

```dart
// Enable smart fallback (default = true)
final partners = await BridgeCore.instance.odoo.searchRead(
  model: 'res.partner',
  fields: ['name', 'email', 'invalid_field', 'phone'],
  useSmartFallback: true, // ← Automatic retry on error
);

// What happens:
// 1. Try with: ['name', 'email', 'invalid_field', 'phone']
// 2. Error: "Invalid field 'invalid_field'"
// 3. Auto retry with: ['name', 'email', 'phone']
// 4. Success! ✅

// Disable fallback (fail immediately on error)
try {
  final partners = await BridgeCore.instance.odoo.searchRead(
    model: 'res.partner',
    fields: ['name', 'invalid_field'],
    useSmartFallback: false, // ← No retry
  );
} catch (e) {
  print('Error: $e'); // Immediate failure
}
```

#### Fallback Levels:

```
Level 1: Original fields (user-provided)
Level 2: Without invalid fields
Level 3: Basic fields (id, name, display_name, create_date, write_date)
Level 4: Minimal fields (id, name, display_name)
Level 5: Fetch valid fields from server
```

#### Clear Invalid Fields Cache:

```dart
// Clear global cache (all models)
FieldFallbackStrategy.clearGlobalCache();

// Clear specific model cache
FieldFallbackStrategy.clearModelCache('res.partner');

// View cached invalid fields
final cache = FieldFallbackStrategy.getGlobalInvalidFieldsCache();
print(cache);
// Output: {'res.partner': ['invalid_field1', 'invalid_field2']}
```

### 4. Retry Interceptor (Network Resilience)

Automatic retry on transient failures:

```dart
// Retry is enabled by default
BridgeCore.initialize(
  baseUrl: 'https://api.yourdomain.com',
  debugMode: true,
  enableRetry: true,
  maxRetries: 5, // Default: 3
);

// What gets retried automatically:
// - 500, 502, 503, 504 errors
// - Connection errors
// - Timeout errors

// What doesn't get retried:
// - 400, 401, 403, 404 errors
// - Validation errors
```

#### Retry Behavior:

```
Attempt 1: Immediate
Attempt 2: After 2 seconds
Attempt 3: After 4 seconds
Attempt 4: After 6 seconds
...

(Exponential backoff: delay = retryDelay * attemptNumber)
```

### 5. Caching

In-memory caching with TTL support:

```dart
// Enable cache at initialization
BridgeCore.initialize(
  baseUrl: 'https://api.yourdomain.com',
  enableCache: true,
);

// Use cache in requests (via HTTP client)
// Cache is automatically used when enabled

// Get cache statistics
final stats = BridgeCore.instance.getCacheStats();
print('Cache entries: ${stats['total_entries']}');

// Clear cache
BridgeCore.instance.clearCache();
```

### 6. Metrics & Logging

Track requests and get statistics:

```dart
// Enable logging at initialization
BridgeCore.initialize(
  baseUrl: 'https://api.yourdomain.com',
  enableLogging: true,
  logLevel: LogLevel.info, // debug, info, warning, error
);

// Or enable/disable at runtime
BridgeCore.instance.setLoggingEnabled(true);
BridgeCore.instance.setLogLevel(LogLevel.debug);

// Get metrics summary
final metrics = BridgeCore.instance.getMetrics();
print('Total Requests: ${metrics['total_requests']}');
print('Success Rate: ${(metrics['success_rate'] * 100).toStringAsFixed(1)}%');
print('Average Duration: ${metrics['average_duration_ms']?.toStringAsFixed(0)}ms');

// Get endpoint statistics
final endpointStats = BridgeCore.instance.getEndpointStats();
endpointStats.forEach((endpoint, stats) {
  print('$endpoint: ${stats['success_rate']} success rate');
});
```

### 7. Using Endpoints Constants

Access endpoint constants for cleaner code:

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

// Access endpoint constants
print(BridgeCoreEndpoints.login);        // /api/v1/auth/tenant/login
print(BridgeCoreEndpoints.searchRead);   // /api/v1/odoo/search_read

// Get all endpoints
final allEndpoints = BridgeCoreEndpoints.getAllEndpoints();
print('Available endpoints: ${allEndpoints.length}');

// Build full URL
final fullUrl = BridgeCoreEndpoints.getFullUrl(
  'https://api.yourdomain.com',
  BridgeCoreEndpoints.searchRead,
);
print(fullUrl); // https://api.yourdomain.com/api/v1/odoo/search_read
```

## 💡 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  // Initialize with all features
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
    debugMode: true,
    enableRetry: true,
    maxRetries: 3,
    enableCache: true,
    enableLogging: true,
    logLevel: LogLevel.info,
  );

  runApp(MyApp());
}

class PartnersPage extends StatefulWidget {
  @override
  _PartnersPageState createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  List<Map<String, dynamic>> _partners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Use preset + smart fallback
      final partners = await BridgeCore.instance.odoo.searchRead(
        model: 'res.partner',
        domain: [['is_company', '=', true]],
        preset: FieldPreset.standard, // ← Preset
        useSmartFallback: true,        // ← Auto retry on invalid fields
        limit: 50,
      );

      if (!mounted) return;
      setState(() {
        _partners = partners;
        _loading = false;
      });
    } on TenantSuspendedException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Account suspended. Please contact support.';
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection. Please try again.';
        _loading = false;
      });
    } on BridgeCoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPartners,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _partners.length,
      itemBuilder: (context, index) {
        final partner = _partners[index];
        return ListTile(
          title: Text(partner['name'] ?? 'N/A'),
          subtitle: Text(partner['email'] ?? 'No email'),
          trailing: Text('#${partner['id']}'),
        );
      },
    );
  }
}
```

## ⚡ Performance Tips

```dart
// ✅ Good: Use presets for common queries
final partners = await odoo.searchRead(
  model: 'res.partner',
  preset: FieldPreset.basic,
);

// ❌ Avoid: Fetching all fields unnecessarily
final partners = await odoo.searchRead(
  model: 'res.partner',
  preset: FieldPreset.all, // Slow!
);

// ✅ Good: Enable smart fallback (caches invalid fields)
final products = await odoo.searchRead(
  model: 'product.product',
  fields: ['name', 'list_price', 'qty_available'],
  useSmartFallback: true, // ← Learns from errors
);

// ✅ Good: Clear cache periodically
void onLogout() {
  FieldFallbackStrategy.clearGlobalCache();
  BridgeCore.instance.clearCache();
  // ... other cleanup
}
```

## 📄 Project Structure

```
bridgecore_flutter/
├── lib/
│   ├── bridgecore_flutter.dart       # Main export
│   └── src/
│       ├── bridgecore.dart           # Main class
│       ├── auth/
│       │   ├── auth_service.dart
│       │   ├── token_manager.dart
│       │   └── models/
│       ├── odoo/
│       │   ├── odoo_service.dart
│       │   ├── field_presets.dart
│       │   └── field_fallback_strategy.dart
│       ├── client/
│       │   ├── http_client.dart
│       │   └── retry_interceptor.dart
│       └── core/
│           ├── exceptions.dart
│           ├── endpoints.dart
│           ├── cache_manager.dart
│           ├── logger.dart
│           └── metrics.dart
├── test/
├── example/
└── pubspec.yaml
```

## 📝 License

MIT License

## 🤝 Support

For issues and questions, contact support@yourdomain.com

