# Changelog

All notable changes to BridgeCore Flutter SDK will be documented in this file.

## [0.2.0] - 2025-11-22

### 🎉 Added

#### New `/me` Endpoint
- **Enhanced User Information** - Comprehensive `/me` endpoint support
  - New `TenantMeResponse` model with full user details
  - Odoo integration data (partner_id, employee_id)
  - Security groups and permissions
  - Multi-company support
  - Optional custom Odoo fields

#### New Models
- `TenantMeResponse` - Complete response from `/me` endpoint
- `TenantMeUser` - Enhanced user model with timestamps
- `TenantMeInfo` - Enhanced tenant model with Odoo details

#### Permission System
- `hasGroup()` - Check if user has specific group
- `hasAnyGroup()` - Check if user has any of specified groups
- `hasAllGroups()` - Check if user has all specified groups
- `canManagePartners` - Check partner management permission
- `hasMultiCompanyAccess` - Check multi-company access
- `canAccessModule()` - Check module access permission

#### Caching
- Automatic caching of `/me` response (5 minutes TTL)
- `forceRefresh` parameter to bypass cache
- `clearMeCache()` method for manual cache clearing
- Cache automatically cleared on logout

#### Example App
- New `ProfilePage` demonstrating `/me` endpoint
- Permission-based UI examples
- Custom fields integration demo

#### Documentation
- `ME_ENDPOINT.md` - Complete guide for `/me` endpoint
- Updated README with `/me` examples
- Permission checking examples

### 🔧 Changed

#### Enhanced Models
- `Tenant` model now includes:
  - `odooDatabase` - Odoo database name
  - `odooVersion` - Odoo version (e.g., "18.0")

#### Authentication Service
- Replaced old `me()` method with enhanced version
- Added caching support for `/me` endpoint
- Logout now clears `/me` cache

### 📝 Technical Details

#### Files Added
- `lib/src/auth/models/tenant_me_response.dart`
- `example/lib/pages/profile_page.dart`
- `ME_ENDPOINT.md`

#### Files Modified
- `lib/src/auth/auth_service.dart` - Added enhanced `me()` method
- `lib/src/auth/models/tenant_session.dart` - Added odooDatabase & odooVersion
- `lib/bridgecore_flutter.dart` - Exported new models
- `example/lib/main.dart` - Added Profile page link
- `pubspec.yaml` - Version bump to 0.2.0

### 🎯 Use Cases

#### Permission-Based Features
```dart
final userInfo = await BridgeCore.instance.auth.me();

if (userInfo.canManagePartners) {
  // Show partner management features
}

if (userInfo.isAdmin) {
  // Show admin panel
}

if (userInfo.isEmployee) {
  // Show employee portal
}
```

#### Custom Fields Integration
```dart
final userInfo = await BridgeCore.instance.auth.me(
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code', 'x_department'],
  ),
);

final employeeCode = userInfo.odooFieldsData?['x_employee_code'];
```

### 🔄 Migration Guide

#### From 0.1.0 to 0.2.0

**No breaking changes!** All existing code continues to work.

To use new features:

```dart
// Old way (still works)
final session = await auth.login(email: email, password: password);
// Limited information available

// New way (recommended)
final session = await auth.login(email: email, password: password);
final userInfo = await auth.me(); // Get detailed information
print('Partner ID: ${userInfo.partnerId}');
print('Groups: ${userInfo.groups}');
print('Is Admin: ${userInfo.isAdmin}');
```

### ⚡ Performance

- `/me` response cached for 5 minutes (configurable)
- Reduced API calls through intelligent caching
- No performance impact on existing functionality

### 🐛 Bug Fixes

None in this release (new features only)

### 🔒 Security

- Secure permission checking system
- Group-based access control
- No changes to token management

---

## [0.1.0] - 2025-11-22

### 🎉 Added

#### New Features
- **Odoo Fields Check** - Verify custom fields during login and fetch their values
  - New `OdooFieldsCheck` model for requesting field verification
  - New `OdooFieldsData` model for field check results
  - Support for checking field existence and fetching field information
  - Automatic field validation during authentication

#### New Exception Types
- `PaymentRequiredException` (402) - For expired trial periods
- `AccountDeletedException` (410) - For deleted accounts

#### Enhanced Models
- `TenantSession` now includes:
  - `odooFieldsData` - Results of Odoo fields check
  - `tokenType` - Token type (already existed, now documented)
  - `expiresIn` - Token expiration time in seconds (already existed, now documented)

- `LoginRequest` now supports:
  - `odooFieldsCheck` - Optional field check during login

#### Documentation
- Added comprehensive documentation for new features
- Added example pages demonstrating new features:
  - `OdooFieldsCheckDemo` - Interactive demo for fields check
  - `ErrorHandlingDemo` - Demo for all exception types
- Updated README with new features and examples

### 🔧 Changed

#### Authentication
- `AuthService.login()` now accepts optional `odooFieldsCheck` parameter
- Enhanced error handling with new exception types

#### HTTP Client
- Added handling for status codes 402 and 410
- Improved error messages and exception mapping

#### Exports
- Exported new models: `OdooFieldsCheck`, `OdooFieldsData`
- Exported new exceptions: `PaymentRequiredException`, `AccountDeletedException`

### 📝 Technical Details

#### Files Added
- `lib/src/auth/models/odoo_fields_check.dart`
- `lib/src/auth/models/odoo_fields_data.dart`
- `example/lib/pages/odoo_fields_check_demo.dart`
- `example/lib/pages/error_handling_demo.dart`

#### Files Modified
- `lib/src/core/exceptions.dart` - Added new exception types
- `lib/src/auth/models/login_request.dart` - Added odooFieldsCheck support
- `lib/src/auth/models/tenant_session.dart` - Added odooFieldsData field
- `lib/src/auth/auth_service.dart` - Updated login method signature
- `lib/src/client/http_client.dart` - Added 402 and 410 error handling
- `lib/bridgecore_flutter.dart` - Added new exports
- `example/lib/main.dart` - Added navigation to new demo pages
- `README.md` - Updated with new features

### 🎯 Use Cases

#### Odoo Fields Check
Perfect for applications that need to:
- Verify employee codes before allowing login
- Check if custom fields exist in specific Odoo versions
- Fetch user department/branch information during login
- Validate custom field configuration

#### Enhanced Error Handling
Better user experience with:
- Trial expiration handling (show upgrade screen)
- Account deletion detection (show appropriate message)
- More granular error handling for different scenarios

### 📚 Examples

#### Basic Odoo Fields Check
```dart
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password123',
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code', 'x_department'],
  ),
);

if (session.odooFieldsData?.success == true) {
  final data = session.odooFieldsData!.data;
  print('Employee Code: ${data?['x_employee_code']}');
}
```

#### Enhanced Error Handling
```dart
try {
  await BridgeCore.instance.auth.login(
    email: email,
    password: password,
  );
} on PaymentRequiredException catch (e) {
  // Show upgrade screen
  navigateToUpgrade();
} on AccountDeletedException catch (e) {
  // Show account deleted message
  showAccountDeletedDialog();
} on TenantSuspendedException catch (e) {
  // Show suspension message
  showSuspensionDialog();
}
```

### 🔄 Migration Guide

#### From Previous Versions

No breaking changes! All existing code will continue to work.

To use new features:

1. **Odoo Fields Check** (Optional)
```dart
// Before
final session = await auth.login(email: email, password: password);

// After (with fields check)
final session = await auth.login(
  email: email,
  password: password,
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code'],
  ),
);
```

2. **Enhanced Error Handling** (Recommended)
```dart
// Before
try {
  await auth.login(email: email, password: password);
} on BridgeCoreException catch (e) {
  print('Error: ${e.message}');
}

// After (more specific)
try {
  await auth.login(email: email, password: password);
} on PaymentRequiredException catch (e) {
  // Handle trial expiration
} on AccountDeletedException catch (e) {
  // Handle deleted account
} on UnauthorizedException catch (e) {
  // Handle invalid credentials
}
```

### ⚡ Performance

- No performance impact on existing functionality
- Odoo Fields Check adds minimal overhead only when used
- All new features are opt-in

### 🐛 Bug Fixes

None in this release (new features only)

### 🔒 Security

- Secure handling of custom field data
- No changes to token management
- All data validated before processing

---

## [0.0.1] - Initial Release

- Basic authentication (login, logout, refresh)
- Odoo CRUD operations
- Field presets
- Smart field fallback
- Retry interceptor
- Caching
- Metrics & logging

