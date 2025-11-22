/// Response model for /me endpoint
///
/// Contains comprehensive user information including:
/// - User profile from BridgeCore
/// - Tenant information
/// - Odoo partner_id and employee_id
/// - Odoo groups and permissions
/// - Company information
/// - Optional custom Odoo fields
class TenantMeResponse {
  final TenantMeUser user;
  final TenantMeInfo tenant;
  final int? partnerId;
  final int? employeeId;
  final List<String> groups;
  final bool isAdmin;
  final bool isInternalUser;
  final List<int> companyIds;
  final int? currentCompanyId;
  final Map<String, dynamic>? odooFieldsData;

  TenantMeResponse({
    required this.user,
    required this.tenant,
    this.partnerId,
    this.employeeId,
    required this.groups,
    required this.isAdmin,
    required this.isInternalUser,
    required this.companyIds,
    this.currentCompanyId,
    this.odooFieldsData,
  });

  factory TenantMeResponse.fromJson(Map<String, dynamic> json) {
    return TenantMeResponse(
      user: TenantMeUser.fromJson(json['user'] as Map<String, dynamic>),
      tenant: TenantMeInfo.fromJson(json['tenant'] as Map<String, dynamic>),
      partnerId: json['partner_id'] as int?,
      employeeId: json['employee_id'] as int?,
      groups: (json['groups'] as List?)?.cast<String>() ?? [],
      isAdmin: json['is_admin'] as bool? ?? false,
      isInternalUser: json['is_internal_user'] as bool? ?? false,
      companyIds: (json['company_ids'] as List?)?.cast<int>() ?? [],
      currentCompanyId: json['current_company_id'] as int?,
      odooFieldsData: json['odoo_fields_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tenant': tenant.toJson(),
      'partner_id': partnerId,
      'employee_id': employeeId,
      'groups': groups,
      'is_admin': isAdmin,
      'is_internal_user': isInternalUser,
      'company_ids': companyIds,
      'current_company_id': currentCompanyId,
      'odoo_fields_data': odooFieldsData,
    };
  }

  /// Check if user has a specific group
  bool hasGroup(String groupXmlId) {
    return groups.contains(groupXmlId);
  }

  /// Check if user has any of the specified groups
  bool hasAnyGroup(List<String> groupXmlIds) {
    return groupXmlIds.any((group) => groups.contains(group));
  }

  /// Check if user has all of the specified groups
  bool hasAllGroups(List<String> groupXmlIds) {
    return groupXmlIds.every((group) => groups.contains(group));
  }

  /// Check if user has access to multiple companies
  bool get isMultiCompany => companyIds.length > 1;

  /// Check if user is an employee in Odoo
  bool get isEmployee => employeeId != null;

  @override
  String toString() {
    return 'TenantMeResponse(user: ${user.fullName}, isAdmin: $isAdmin, '
        'partnerId: $partnerId, groups: ${groups.length})';
  }
}

/// User model for /me response
class TenantMeUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final int? odooUserId;
  final DateTime createdAt;
  final DateTime? lastLogin;

  TenantMeUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.odooUserId,
    required this.createdAt,
    this.lastLogin,
  });

  factory TenantMeUser.fromJson(Map<String, dynamic> json) {
    return TenantMeUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      odooUserId: json['odoo_user_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'odoo_user_id': odooUserId,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TenantMeUser(id: $id, email: $email, fullName: $fullName)';
  }
}

/// Tenant info model for /me response
class TenantMeInfo {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String odooUrl;
  final String odooDatabase;
  final String? odooVersion;

  TenantMeInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.odooUrl,
    required this.odooDatabase,
    this.odooVersion,
  });

  factory TenantMeInfo.fromJson(Map<String, dynamic> json) {
    return TenantMeInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
      odooUrl: json['odoo_url'] as String,
      odooDatabase: json['odoo_database'] as String,
      odooVersion: json['odoo_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'status': status,
      'odoo_url': odooUrl,
      'odoo_database': odooDatabase,
      'odoo_version': odooVersion,
    };
  }

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isTrial => status == 'trial';

  @override
  String toString() {
    return 'TenantMeInfo(name: $name, database: $odooDatabase, status: $status)';
  }
}

/// Extension methods for permission checks
extension TenantMePermissions on TenantMeResponse {
  /// Common Odoo groups
  static const String groupUser = 'base.group_user';
  static const String groupSystem = 'base.group_system';
  static const String groupErpManager = 'base.group_erp_manager';
  static const String groupPartnerManager = 'base.group_partner_manager';
  static const String groupMultiCompany = 'base.group_multi_company';

  /// Check if user can access a specific module
  bool canAccessModule(String moduleName) {
    return hasGroup('$moduleName.group_user') ||
        hasGroup('$moduleName.group_manager') ||
        isAdmin;
  }

  /// Check if user can manage partners
  bool get canManagePartners =>
      hasGroup(groupPartnerManager) || isAdmin;

  /// Check if user has multi-company access
  bool get hasMultiCompanyAccess =>
      hasGroup(groupMultiCompany) || isMultiCompany;
}

