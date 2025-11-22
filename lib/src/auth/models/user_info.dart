import 'tenant_session.dart';

/// User information response from /me endpoint
class UserInfo {
  final TenantUser user;
  final Tenant tenant;

  UserInfo({
    required this.user,
    required this.tenant,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      user: TenantUser.fromJson(json['user'] as Map<String, dynamic>),
      tenant: Tenant.fromJson(json['tenant'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tenant': tenant.toJson(),
    };
  }
}
