import '../client/http_client.dart';
import '../core/endpoints.dart';
import 'models/notification.dart';
import 'models/notification_preference.dart';
import 'models/device_token.dart';

/// Notification service for managing user notifications
///
/// Provides methods to:
/// - List and manage notifications
/// - Mark notifications as read
/// - Manage notification preferences
/// - Register devices for push notifications
///
/// Example:
/// ```dart
/// // Get notifications
/// final response = await notifications.list();
/// print('Unread: ${response.unreadCount}');
///
/// // Mark as read
/// await notifications.markAsRead(notificationId);
///
/// // Register device for push
/// await notifications.registerDevice(
///   deviceId: 'device-123',
///   deviceType: 'android',
///   token: 'fcm-token...',
/// );
/// ```
class NotificationService {
  final BridgeCoreHttpClient httpClient;

  NotificationService({required this.httpClient});

  // ========================================================================
  // Notification Operations
  // ========================================================================

  /// List user notifications
  Future<NotificationListResponse> list({
    bool? isRead,
    NotificationType? type,
    int skip = 0,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      if (isRead != null) 'is_read': isRead,
      if (type != null) 'notification_type': type.value,
      'skip': skip,
      'limit': limit,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await httpClient.get(
      '${BridgeCoreEndpoints.notificationList}?$queryString',
    );

    return NotificationListResponse.fromJson(response);
  }

  /// Get notification by ID
  Future<AppNotification> get(String notificationId) async {
    final response = await httpClient.get(
      '${BridgeCoreEndpoints.notificationGet}/$notificationId',
    );

    return AppNotification.fromJson(response);
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    final response = await httpClient.post(
      '${BridgeCoreEndpoints.notificationMarkRead}/$notificationId/read',
      {},
    );

    return response['success'] ?? false;
  }

  /// Mark multiple notifications as read
  Future<int> markMultipleAsRead(List<String> notificationIds) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.notificationMarkMultipleRead,
      {'notification_ids': notificationIds},
    );

    return response['marked_count'] ?? 0;
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.notificationReadAll,
      {},
    );

    return response['marked_count'] ?? 0;
  }

  /// Delete a notification
  Future<bool> delete(String notificationId) async {
    final response = await httpClient.delete(
      '${BridgeCoreEndpoints.notificationDelete}/$notificationId',
    );

    return response['success'] ?? false;
  }

  /// Get notification statistics
  Future<NotificationStats> getStats() async {
    final response = await httpClient.get(
      BridgeCoreEndpoints.notificationStats,
    );

    return NotificationStats.fromJson(response);
  }

  // ========================================================================
  // Preferences Operations
  // ========================================================================

  /// Get notification preferences
  Future<NotificationPreference> getPreferences() async {
    final response = await httpClient.get(
      BridgeCoreEndpoints.notificationPreferences,
    );

    return NotificationPreference.fromJson(response);
  }

  /// Update notification preferences
  Future<NotificationPreference> updatePreferences({
    bool? enableInApp,
    bool? enablePush,
    bool? enableEmail,
    bool? enableSms,
    bool? receiveInfo,
    bool? receiveSuccess,
    bool? receiveWarning,
    bool? receiveError,
    bool? receiveSystem,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? quietHoursTimezone,
    bool? emailDigestEnabled,
    String? emailDigestFrequency,
  }) async {
    final response = await httpClient.put(
      BridgeCoreEndpoints.notificationUpdatePreferences,
      {
        if (enableInApp != null) 'enable_in_app': enableInApp,
        if (enablePush != null) 'enable_push': enablePush,
        if (enableEmail != null) 'enable_email': enableEmail,
        if (enableSms != null) 'enable_sms': enableSms,
        if (receiveInfo != null) 'receive_info': receiveInfo,
        if (receiveSuccess != null) 'receive_success': receiveSuccess,
        if (receiveWarning != null) 'receive_warning': receiveWarning,
        if (receiveError != null) 'receive_error': receiveError,
        if (receiveSystem != null) 'receive_system': receiveSystem,
        if (quietHoursEnabled != null) 'quiet_hours_enabled': quietHoursEnabled,
        if (quietHoursStart != null) 'quiet_hours_start': quietHoursStart,
        if (quietHoursEnd != null) 'quiet_hours_end': quietHoursEnd,
        if (quietHoursTimezone != null) 'quiet_hours_timezone': quietHoursTimezone,
        if (emailDigestEnabled != null) 'email_digest_enabled': emailDigestEnabled,
        if (emailDigestFrequency != null) 'email_digest_frequency': emailDigestFrequency,
      },
    );

    return NotificationPreference.fromJson(response);
  }

  // ========================================================================
  // Device Registration
  // ========================================================================

  /// Register device for push notifications
  Future<DeviceToken> registerDevice({
    required String deviceId,
    String? deviceName,
    required String deviceType,
    required String token,
    String tokenType = 'fcm',
    String? appVersion,
    String? osVersion,
  }) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.notificationRegisterDevice,
      {
        'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
        'device_type': deviceType,
        'token': token,
        'token_type': tokenType,
        if (appVersion != null) 'app_version': appVersion,
        if (osVersion != null) 'os_version': osVersion,
      },
    );

    return DeviceToken.fromJson(response);
  }

  /// Unregister device from push notifications
  Future<bool> unregisterDevice(String deviceId) async {
    final response = await httpClient.post(
      BridgeCoreEndpoints.notificationUnregisterDevice,
      {'device_id': deviceId},
    );

    return response['success'] ?? false;
  }

  /// List registered devices
  Future<DeviceTokenListResponse> listDevices() async {
    final response = await httpClient.get(
      BridgeCoreEndpoints.notificationDevices,
    );

    return DeviceTokenListResponse.fromJson(response);
  }
}

