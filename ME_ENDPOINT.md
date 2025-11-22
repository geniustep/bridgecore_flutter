# 👤 `/me` Endpoint - Complete Guide

## Overview

The `/me` endpoint provides comprehensive information about the currently authenticated user, including their profile, tenant details, Odoo integration data, permissions, and optionally custom Odoo fields.

**Endpoint:** `POST /api/v1/auth/tenant/me`

**Authentication:** Required (Bearer Token)

---

## 🚀 Basic Usage

### Simple Request (No Custom Fields)

```dart
final userInfo = await BridgeCore.instance.auth.me();

print('User: ${userInfo.user.fullName}');
print('Partner ID: ${userInfo.partnerId}');
print('Is Admin: ${userInfo.isAdmin}');
print('Groups: ${userInfo.groups}');
```

### With Custom Odoo Fields

```dart
final userInfo = await BridgeCore.instance.auth.me(
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['phone', 'mobile', 'shuttle_role', 'x_employee_code'],
  ),
);

// Access custom fields
final customFields = userInfo.odooFieldsData;
print('Phone: ${customFields?['phone']}');
print('Employee Code: ${customFields?['x_employee_code']}');
```

### Force Refresh (Bypass Cache)

```dart
// By default, /me response is cached for 5 minutes
// To force a fresh fetch:
final freshInfo = await BridgeCore.instance.auth.me(forceRefresh: true);
```

---

## 📦 Response Model

### TenantMeResponse

```dart
class TenantMeResponse {
  final TenantMeUser user;              // User profile
  final TenantMeInfo tenant;            // Tenant information
  final int? partnerId;                 // Odoo partner ID
  final int? employeeId;                // Odoo employee ID (if user is employee)
  final List<String> groups;            // Odoo security groups
  final bool isAdmin;                   // Is user admin?
  final bool isInternalUser;            // Is internal Odoo user?
  final List<int> companyIds;           // Accessible company IDs
  final int? currentCompanyId;          // Current active company
  final Map<String, dynamic>? odooFieldsData;  // Custom fields data
}
```

### TenantMeUser

```dart
class TenantMeUser {
  final String id;                      // BridgeCore user ID
  final String email;                   // User email
  final String fullName;                // Full name
  final String role;                    // User role (admin, user, etc.)
  final int? odooUserId;                // Odoo user ID
  final DateTime createdAt;             // Account creation date
  final DateTime? lastLogin;            // Last login timestamp
}
```

### TenantMeInfo

```dart
class TenantMeInfo {
  final String id;                      // Tenant ID
  final String name;                    // Tenant name
  final String slug;                    // Tenant slug
  final String status;                  // Status (active, trial, suspended)
  final String odooUrl;                 // Odoo instance URL
  final String odooDatabase;            // Odoo database name
  final String? odooVersion;            // Odoo version (e.g., "18.0")
}
```

---

## 🔐 Permission Checks

### Built-in Helper Methods

```dart
final userInfo = await BridgeCore.instance.auth.me();

// Check specific group
if (userInfo.hasGroup('base.group_system')) {
  print('User is a system administrator');
}

// Check any of multiple groups
if (userInfo.hasAnyGroup(['sales_team.group_sale_manager', 'base.group_erp_manager'])) {
  print('User can manage sales or is ERP manager');
}

// Check all groups
if (userInfo.hasAllGroups(['base.group_user', 'base.group_partner_manager'])) {
  print('User has both required permissions');
}

// Check if employee
if (userInfo.isEmployee) {
  print('User is an employee with ID: ${userInfo.employeeId}');
}

// Check multi-company
if (userInfo.isMultiCompany) {
  print('User has access to ${userInfo.companyIds.length} companies');
}
```

### Extension Methods

```dart
// Can manage partners?
if (userInfo.canManagePartners) {
  // Show partner management features
}

// Has multi-company access?
if (userInfo.hasMultiCompanyAccess) {
  // Show company switcher
}

// Can access specific module?
if (userInfo.canAccessModule('sale')) {
  // Show sales module
}
```

### Common Odoo Groups

```dart
// Access predefined group constants
TenantMePermissions.groupUser              // 'base.group_user'
TenantMePermissions.groupSystem            // 'base.group_system'
TenantMePermissions.groupErpManager        // 'base.group_erp_manager'
TenantMePermissions.groupPartnerManager    // 'base.group_partner_manager'
TenantMePermissions.groupMultiCompany      // 'base.group_multi_company'
```

---

## 💾 Caching

The `/me` endpoint response is automatically cached for **5 minutes** to improve performance and reduce API calls.

### Cache Behavior

```dart
// First call - fetches from API
final userInfo1 = await BridgeCore.instance.auth.me();

// Second call within 5 minutes - returns cached data
final userInfo2 = await BridgeCore.instance.auth.me();

// Force refresh - bypasses cache
final userInfo3 = await BridgeCore.instance.auth.me(forceRefresh: true);

// With custom fields - always fetches fresh (not cached)
final userInfo4 = await BridgeCore.instance.auth.me(
  odooFieldsCheck: OdooFieldsCheck(model: 'res.users', listFields: ['phone']),
);
```

### Manual Cache Management

```dart
// Clear /me cache manually
BridgeCore.instance.auth.clearMeCache();

// Cache is automatically cleared on logout
await BridgeCore.instance.auth.logout(); // Clears cache
```

---

## 🎯 Use Cases

### 1. User Profile Screen

```dart
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TenantMeResponse? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userInfo = await BridgeCore.instance.auth.me();
    setState(() => _userInfo = userInfo);
  }

  @override
  Widget build(BuildContext context) {
    if (_userInfo == null) return CircularProgressIndicator();

    return ListView(
      children: [
        Text('Name: ${_userInfo!.user.fullName}'),
        Text('Email: ${_userInfo!.user.email}'),
        Text('Role: ${_userInfo!.user.role}'),
        Text('Partner ID: ${_userInfo!.partnerId}'),
        Text('Groups: ${_userInfo!.groups.join(", ")}'),
      ],
    );
  }
}
```

### 2. Permission-Based UI

```dart
class HomePage extends StatelessWidget {
  final TenantMeResponse userInfo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Show to all users
        ListTile(title: Text('Dashboard')),
        
        // Show only to users who can manage partners
        if (userInfo.canManagePartners)
          ListTile(title: Text('Manage Partners')),
        
        // Show only to admins
        if (userInfo.isAdmin)
          ListTile(title: Text('Admin Panel')),
        
        // Show only to employees
        if (userInfo.isEmployee)
          ListTile(title: Text('Employee Portal')),
        
        // Show only to multi-company users
        if (userInfo.isMultiCompany)
          ListTile(title: Text('Switch Company')),
      ],
    );
  }
}
```

### 3. Role-Based Access Control

```dart
Future<bool> canAccessFeature(String featureName) async {
  final userInfo = await BridgeCore.instance.auth.me();
  
  switch (featureName) {
    case 'sales':
      return userInfo.canAccessModule('sale') || userInfo.isAdmin;
    
    case 'inventory':
      return userInfo.canAccessModule('stock') || userInfo.isAdmin;
    
    case 'accounting':
      return userInfo.canAccessModule('account') || userInfo.isAdmin;
    
    case 'hr':
      return userInfo.canAccessModule('hr') || userInfo.isEmployee;
    
    default:
      return false;
  }
}
```

### 4. Custom Field Validation

```dart
Future<bool> validateEmployeeAccess() async {
  final userInfo = await BridgeCore.instance.auth.me(
    odooFieldsCheck: OdooFieldsCheck(
      model: 'res.users',
      listFields: ['x_employee_code', 'x_department'],
    ),
  );
  
  final employeeCode = userInfo.odooFieldsData?['x_employee_code'];
  final department = userInfo.odooFieldsData?['x_department'];
  
  if (employeeCode == null || employeeCode.toString().isEmpty) {
    showError('Employee code not configured');
    return false;
  }
  
  if (department == null) {
    showError('Department not assigned');
    return false;
  }
  
  return true;
}
```

---

## ⚠️ Error Handling

```dart
try {
  final userInfo = await BridgeCore.instance.auth.me();
  // Success
} on UnauthorizedException catch (e) {
  // Token expired or invalid
  print('Please login again');
  navigateToLogin();
} on NetworkException catch (e) {
  // Network error
  print('Check your internet connection');
} on BridgeCoreException catch (e) {
  // Other errors
  print('Error: ${e.message}');
}
```

---

## 🔄 Comparison with Login Response

### Login Response
- Contains: `accessToken`, `refreshToken`, `user`, `tenant`
- Purpose: Initial authentication
- When: After successful login

### /me Response
- Contains: Everything from login + `partnerId`, `employeeId`, `groups`, `permissions`, `companies`
- Purpose: Detailed user information
- When: Anytime after authentication

### When to Use Each

```dart
// Use login for authentication
final loginResponse = await BridgeCore.instance.auth.login(...);
// Save tokens, basic user info

// Use /me for detailed information
final userInfo = await BridgeCore.instance.auth.me();
// Get permissions, groups, Odoo integration details
```

---

## 📊 Performance Tips

1. **Use Caching**: Don't call `/me` repeatedly - it's cached for 5 minutes
2. **Fetch Once**: Load user info once at app startup and reuse
3. **Custom Fields**: Only request custom fields when needed
4. **Force Refresh**: Only use `forceRefresh: true` when necessary

```dart
// ✅ Good: Load once at startup
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TenantMeResponse? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    _userInfo = await BridgeCore.instance.auth.me();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _userInfo != null 
        ? HomePage(userInfo: _userInfo!) 
        : LoadingScreen(),
    );
  }
}

// ❌ Bad: Calling /me in every widget
class SomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Don't do this!
    return FutureBuilder(
      future: BridgeCore.instance.auth.me(),
      builder: (context, snapshot) {
        // ...
      },
    );
  }
}
```

---

## 🧪 Testing

```dart
// Mock /me response for testing
final mockUserInfo = TenantMeResponse(
  user: TenantMeUser(
    id: 'test-user-id',
    email: 'test@example.com',
    fullName: 'Test User',
    role: 'admin',
    odooUserId: 1,
    createdAt: DateTime.now(),
  ),
  tenant: TenantMeInfo(
    id: 'test-tenant-id',
    name: 'Test Tenant',
    slug: 'test-tenant',
    status: 'active',
    odooUrl: 'https://test.odoo.com',
    odooDatabase: 'test_db',
    odooVersion: '18.0',
  ),
  partnerId: 1,
  employeeId: 1,
  groups: ['base.group_user', 'base.group_system'],
  isAdmin: true,
  isInternalUser: true,
  companyIds: [1, 2],
  currentCompanyId: 1,
  odooFieldsData: {'phone': '+1234567890'},
);
```

---

## 📚 Related Documentation

- [Authentication Guide](AUTHENTICATION_GUIDE.md)
- [Odoo Fields Check](ODOO_FIELDS_CHECK.md)
- [Error Handling](README.md#error-handling)
- [Permissions Guide](PERMISSIONS.md)

---

## 🆕 What's New

**Version 0.2.0**
- ✅ Added `/me` endpoint support
- ✅ Enhanced user information with Odoo integration
- ✅ Permission checking helper methods
- ✅ Automatic caching (5 minutes)
- ✅ Support for custom Odoo fields
- ✅ Multi-company support
- ✅ Employee detection

---

**Last Updated**: 2025-11-22

