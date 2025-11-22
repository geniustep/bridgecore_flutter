# 🎉 New Features in BridgeCore Flutter SDK

## Overview

This document highlights the new features added to BridgeCore Flutter SDK based on the official BridgeCore API documentation.

---

## 1️⃣ Odoo Fields Check 🆕

### What is it?

A powerful feature that allows you to verify custom fields in Odoo during the login process and fetch their values immediately.

### Why use it?

- ✅ **Validate Custom Fields** - Ensure custom fields exist before proceeding
- ✅ **Fetch User Data** - Get employee codes, departments, branches, etc.
- ✅ **Version Compatibility** - Check if fields exist in specific Odoo versions
- ✅ **Early Validation** - Catch configuration issues at login time

### How to use it?

```dart
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password123',
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code', 'x_department', 'x_branch_id'],
  ),
);

// Check results
if (session.odooFieldsData?.success == true) {
  final fieldsData = session.odooFieldsData!;
  
  // Check if all fields exist
  if (fieldsData.fieldsExist) {
    print('✅ All fields exist!');
    
    // Get field information
    fieldsData.fieldsInfo?.forEach((name, info) {
      print('Field: ${info.name} (${info.ttype})');
      print('Description: ${info.fieldDescription}');
    });
    
    // Get actual data
    final data = fieldsData.data;
    print('Employee Code: ${data?['x_employee_code']}');
    print('Department: ${data?['x_department']}');
  } else {
    print('⚠️ Some fields are missing');
  }
}
```

### Real-world Example

```dart
// Use case: Verify employee code before allowing access
Future<bool> loginEmployee(String email, String password) async {
  try {
    final session = await BridgeCore.instance.auth.login(
      email: email,
      password: password,
      odooFieldsCheck: OdooFieldsCheck(
        model: 'res.users',
        listFields: ['x_employee_code', 'x_department'],
      ),
    );
    
    // Check if employee code exists
    final employeeCode = session.odooFieldsData?.data?['x_employee_code'];
    
    if (employeeCode == null || employeeCode.toString().isEmpty) {
      showError('Employee code not configured. Contact HR.');
      await BridgeCore.instance.auth.logout();
      return false;
    }
    
    // Save employee info for later use
    await saveEmployeeInfo(
      code: employeeCode.toString(),
      department: session.odooFieldsData?.data?['x_department']?.toString(),
    );
    
    return true;
  } catch (e) {
    showError('Login failed: $e');
    return false;
  }
}
```

---

## 2️⃣ Enhanced Error Handling 🆕

### New Exception Types

#### PaymentRequiredException (402)

Thrown when the trial period has expired.

```dart
try {
  await BridgeCore.instance.auth.login(email: email, password: password);
} on PaymentRequiredException catch (e) {
  // Show upgrade screen
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Trial Expired'),
      content: Text('Your trial period has ended. Please upgrade to continue.'),
      actions: [
        TextButton(
          onPressed: () => navigateToUpgrade(),
          child: Text('Upgrade Now'),
        ),
      ],
    ),
  );
}
```

#### AccountDeletedException (410)

Thrown when the account has been deleted.

```dart
try {
  await BridgeCore.instance.auth.login(email: email, password: password);
} on AccountDeletedException catch (e) {
  // Show account deleted message
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Account Deleted'),
      content: Text('This account has been deleted and can no longer be accessed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

### Complete Error Handling Example

```dart
Future<void> handleLogin(String email, String password) async {
  try {
    final session = await BridgeCore.instance.auth.login(
      email: email,
      password: password,
    );
    
    // Success - navigate to home
    navigateToHome();
    
  } on PaymentRequiredException catch (e) {
    // Trial expired - show upgrade screen
    showError('Your trial has expired. Please upgrade your account.');
    navigateToUpgrade();
    
  } on AccountDeletedException catch (e) {
    // Account deleted
    showError('This account has been deleted.');
    
  } on TenantSuspendedException catch (e) {
    // Account suspended
    showError('Your account is suspended. Please contact support.');
    showSupportContact();
    
  } on UnauthorizedException catch (e) {
    // Invalid credentials
    showError('Invalid email or password. Please try again.');
    
  } on NetworkException catch (e) {
    // Network error
    showError('No internet connection. Please check your network.');
    
  } on BridgeCoreException catch (e) {
    // Generic error
    showError('An error occurred: ${e.message}');
  }
}
```

---

## 3️⃣ Enhanced Session Information

### Token Information

The `TenantSession` model now properly exposes token information:

```dart
final session = await BridgeCore.instance.auth.login(
  email: email,
  password: password,
);

print('Token Type: ${session.tokenType}');        // "bearer"
print('Expires In: ${session.expiresIn} seconds'); // 1800
print('User: ${session.user.fullName}');
print('Tenant: ${session.tenant.name}');
print('Status: ${session.tenant.status}');

// Calculate expiration time
final expiresAt = DateTime.now().add(Duration(seconds: session.expiresIn));
print('Token expires at: $expiresAt');
```

---

## 📊 Comparison: Before vs After

### Before (v0.0.1)

```dart
// Basic login
try {
  final session = await auth.login(email: email, password: password);
  print('Logged in!');
} on BridgeCoreException catch (e) {
  print('Error: ${e.message}');
}
```

### After (v0.1.0)

```dart
// Enhanced login with fields check and specific error handling
try {
  final session = await auth.login(
    email: email,
    password: password,
    odooFieldsCheck: OdooFieldsCheck(
      model: 'res.users',
      listFields: ['x_employee_code', 'x_department'],
    ),
  );
  
  // Check custom fields
  if (session.odooFieldsData?.success == true) {
    print('Employee: ${session.odooFieldsData!.data?['x_employee_code']}');
  }
  
  print('Token expires in: ${session.expiresIn}s');
  
} on PaymentRequiredException catch (e) {
  navigateToUpgrade();
} on AccountDeletedException catch (e) {
  showAccountDeletedMessage();
} on TenantSuspendedException catch (e) {
  showSuspensionMessage();
} on UnauthorizedException catch (e) {
  showInvalidCredentialsError();
}
```

---

## 🎯 Use Cases

### 1. Employee Management App

```dart
// Verify employee code and department
final session = await auth.login(
  email: email,
  password: password,
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_employee_code', 'x_department', 'x_manager_id'],
  ),
);

// Use employee data throughout the app
final employeeCode = session.odooFieldsData?.data?['x_employee_code'];
final department = session.odooFieldsData?.data?['x_department'];
```

### 2. Multi-tenant SaaS App

```dart
// Handle trial expiration gracefully
try {
  await auth.login(email: email, password: password);
} on PaymentRequiredException catch (e) {
  // Show upgrade options based on tenant
  final plans = await fetchAvailablePlans();
  showUpgradeDialog(plans);
}
```

### 3. Field Service App

```dart
// Verify technician fields
final session = await auth.login(
  email: email,
  password: password,
  odooFieldsCheck: OdooFieldsCheck(
    model: 'res.users',
    listFields: ['x_technician_level', 'x_service_area', 'x_vehicle_id'],
  ),
);

// Only allow access if technician fields are configured
if (!session.odooFieldsData?.fieldsExist ?? false) {
  showError('Your account is not configured as a technician.');
  await auth.logout();
}
```

---

## 🚀 Getting Started

### 1. Update your dependencies

```yaml
dependencies:
  bridgecore_flutter: ^0.1.0
```

### 2. Try the examples

Run the example app to see the new features in action:

```bash
cd example
flutter run
```

Navigate to:
- **Odoo Fields Check Demo** - Interactive demo
- **Error Handling Demo** - Test all exception types

### 3. Update your code

Add the new features to your existing code:

1. Add `odooFieldsCheck` to your login calls (optional)
2. Update error handling to use specific exception types (recommended)
3. Use token expiration information for better UX (optional)

---

## 📚 Documentation

- **README.md** - Complete SDK documentation
- **CHANGELOG.md** - Detailed changelog
- **Example App** - Live demos of all features

---

## 💡 Tips

1. **Start Simple** - Try basic login first, then add fields check
2. **Handle Errors** - Use specific exception types for better UX
3. **Test Thoroughly** - Use the demo pages to understand behavior
4. **Check Fields** - Verify custom fields exist before using them

---

## 🆘 Support

If you encounter any issues:

1. Check the example app for working code
2. Review the README for detailed documentation
3. Check CHANGELOG for migration notes
4. Contact support if needed

---

**Happy Coding! 🎉**

