import 'odoo_fields_check.dart';

/// Login request model
class LoginRequest {
  final String email;
  final String password;
  final OdooFieldsCheck? odooFieldsCheck;

  LoginRequest({
    required this.email,
    required this.password,
    this.odooFieldsCheck,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (odooFieldsCheck != null) {
      json['odoo_fields_check'] = odooFieldsCheck!.toJson();
    }

    return json;
  }
}
