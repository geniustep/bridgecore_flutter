/// Device token model for push notifications
class DeviceToken {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String deviceType;
  final String tokenType;
  final bool isActive;
  final DateTime? lastUsedAt;
  final String? appVersion;
  final String? osVersion;
  final DateTime createdAt;

  DeviceToken({
    required this.id,
    required this.deviceId,
    this.deviceName,
    required this.deviceType,
    required this.tokenType,
    required this.isActive,
    this.lastUsedAt,
    this.appVersion,
    this.osVersion,
    required this.createdAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      tokenType: json['token_type'] ?? 'fcm',
      isActive: json['is_active'] ?? true,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
      appVersion: json['app_version'],
      osVersion: json['os_version'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'token_type': tokenType,
      'is_active': isActive,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'app_version': appVersion,
      'os_version': osVersion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Device token list response
class DeviceTokenListResponse {
  final List<DeviceToken> devices;
  final int total;

  DeviceTokenListResponse({
    required this.devices,
    required this.total,
  });

  factory DeviceTokenListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceTokenListResponse(
      devices: (json['devices'] as List)
          .map((e) => DeviceToken.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}

