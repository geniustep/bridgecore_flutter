/// Notification type
enum NotificationType {
  info('info'),
  success('success'),
  warning('warning'),
  error('error'),
  system('system');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.info,
    );
  }
}

/// Notification priority
enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  final String value;
  const NotificationPriority(this.value);

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

/// App notification model
/// Named AppNotification to avoid conflict with Flutter's Notification
class AppNotification {
  final String id;
  final String tenantId;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final List<String> channels;
  final bool isRead;
  final DateTime? readAt;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final String? relatedModel;
  final int? relatedId;
  final Map<String, dynamic>? metadata;
  final DateTime? expiresAt;
  final String? source;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.channels,
    required this.isRead,
    this.readAt,
    this.actionType,
    this.actionData,
    this.relatedModel,
    this.relatedId,
    this.metadata,
    this.expiresAt,
    this.source,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      tenantId: json['tenant_id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.fromString(json['type'] ?? 'info'),
      priority: NotificationPriority.fromString(json['priority'] ?? 'normal'),
      channels: List<String>.from(json['channels'] ?? []),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      actionType: json['action_type'],
      actionData: json['action_data'],
      relatedModel: json['related_model'],
      relatedId: json['related_id'],
      metadata: json['metadata'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      source: json['source'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.value,
      'priority': priority.value,
      'channels': channels,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'action_type': actionType,
      'action_data': actionData,
      'related_model': relatedModel,
      'related_id': relatedId,
      'metadata': metadata,
      'expires_at': expiresAt?.toIso8601String(),
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if notification has an action
  bool get hasAction => actionType != null && actionData != null;

  /// Check if notification is expired
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

/// Notification list response
class NotificationListResponse {
  final List<AppNotification> notifications;
  final int total;
  final int unreadCount;
  final int skip;
  final int limit;

  NotificationListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.skip,
    required this.limit,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['notifications'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 50,
    );
  }
}

/// Notification statistics
class NotificationStats {
  final int totalNotifications;
  final int unreadCount;
  final int readCount;
  final int notificationsToday;
  final int notificationsThisWeek;
  final Map<String, int> byType;
  final Map<String, int> byPriority;

  NotificationStats({
    required this.totalNotifications,
    required this.unreadCount,
    required this.readCount,
    required this.notificationsToday,
    required this.notificationsThisWeek,
    required this.byType,
    required this.byPriority,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalNotifications: json['total_notifications'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      readCount: json['read_count'] ?? 0,
      notificationsToday: json['notifications_today'] ?? 0,
      notificationsThisWeek: json['notifications_this_week'] ?? 0,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      byPriority: Map<String, int>.from(json['by_priority'] ?? {}),
    );
  }
}

