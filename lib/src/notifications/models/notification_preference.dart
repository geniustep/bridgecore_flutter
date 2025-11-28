/// Notification preference model
class NotificationPreference {
  final String id;
  final String userId;
  final bool enableInApp;
  final bool enablePush;
  final bool enableEmail;
  final bool enableSms;
  final bool receiveInfo;
  final bool receiveSuccess;
  final bool receiveWarning;
  final bool receiveError;
  final bool receiveSystem;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String quietHoursTimezone;
  final bool emailDigestEnabled;
  final String emailDigestFrequency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationPreference({
    required this.id,
    required this.userId,
    required this.enableInApp,
    required this.enablePush,
    required this.enableEmail,
    required this.enableSms,
    required this.receiveInfo,
    required this.receiveSuccess,
    required this.receiveWarning,
    required this.receiveError,
    required this.receiveSystem,
    required this.quietHoursEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.quietHoursTimezone,
    required this.emailDigestEnabled,
    required this.emailDigestFrequency,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'],
      userId: json['user_id'],
      enableInApp: json['enable_in_app'] ?? true,
      enablePush: json['enable_push'] ?? true,
      enableEmail: json['enable_email'] ?? true,
      enableSms: json['enable_sms'] ?? false,
      receiveInfo: json['receive_info'] ?? true,
      receiveSuccess: json['receive_success'] ?? true,
      receiveWarning: json['receive_warning'] ?? true,
      receiveError: json['receive_error'] ?? true,
      receiveSystem: json['receive_system'] ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      quietHoursTimezone: json['quiet_hours_timezone'] ?? 'UTC',
      emailDigestEnabled: json['email_digest_enabled'] ?? false,
      emailDigestFrequency: json['email_digest_frequency'] ?? 'daily',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'enable_in_app': enableInApp,
      'enable_push': enablePush,
      'enable_email': enableEmail,
      'enable_sms': enableSms,
      'receive_info': receiveInfo,
      'receive_success': receiveSuccess,
      'receive_warning': receiveWarning,
      'receive_error': receiveError,
      'receive_system': receiveSystem,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'quiet_hours_timezone': quietHoursTimezone,
      'email_digest_enabled': emailDigestEnabled,
      'email_digest_frequency': emailDigestFrequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Check if quiet hours are configured
  bool get hasQuietHours =>
      quietHoursEnabled && quietHoursStart != null && quietHoursEnd != null;
}

