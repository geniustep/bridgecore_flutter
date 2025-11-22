import 'odoo_fields_data.dart';

/// Tenant session response after successful login
class TenantSession {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final TenantUser user;
  final Tenant tenant;
  final OdooFieldsData? odooFieldsData;

  TenantSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.tenant,
    this.odooFieldsData,
  });

  factory TenantSession.fromJson(Map<String, dynamic> json) {
    return TenantSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int,
      user: TenantUser.fromJson(json['user'] as Map<String, dynamic>),
      tenant: Tenant.fromJson(json['tenant'] as Map<String, dynamic>),
      odooFieldsData: json['odoo_fields_data'] != null
          ? OdooFieldsData.fromJson(json['odoo_fields_data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
      'tenant': tenant.toJson(),
      if (odooFieldsData != null) 'odoo_fields_data': odooFieldsData!.toJson(),
    };
  }
}

/// Tenant user information
class TenantUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final int? odooUserId;

  TenantUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.odooUserId,
  });

  factory TenantUser.fromJson(Map<String, dynamic> json) {
    return TenantUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      odooUserId: json['odoo_user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'odoo_user_id': odooUserId,
    };
  }
}

/// Tenant information
class Tenant {
  final String id;
  final String name;
  final String slug;
  final String status;

  Tenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
  });

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isTrial => status == 'trial';

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'status': status,
    };
  }
}
