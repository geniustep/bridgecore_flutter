/// Request model for Odoo fields check during login
///
/// This allows you to verify custom fields in Odoo and fetch their values
/// during the login process.
///
/// Example:
/// ```dart
/// final fieldsCheck = OdooFieldsCheck(
///   model: 'res.users',
///   listFields: ['x_employee_code', 'x_department', 'x_branch_id'],
/// );
/// ```
class OdooFieldsCheck {
  /// Odoo model name (e.g., 'res.users', 'res.partner')
  final String model;

  /// List of field names to check and fetch
  final List<String> listFields;

  OdooFieldsCheck({
    required this.model,
    required this.listFields,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'list_fields': listFields,
    };
  }

  /// Create from JSON
  factory OdooFieldsCheck.fromJson(Map<String, dynamic> json) {
    return OdooFieldsCheck(
      model: json['model'] as String,
      listFields: (json['list_fields'] as List).cast<String>(),
    );
  }

  @override
  String toString() {
    return 'OdooFieldsCheck(model: $model, fields: ${listFields.length})';
  }
}

