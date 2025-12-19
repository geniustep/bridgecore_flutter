import 'mail_message.dart';
import 'mail_channel.dart';

/// Response for channel list
class ChannelListResponse {
  final List<MailChannel> channels;
  final int total;

  ChannelListResponse({
    required this.channels,
    required this.total,
  });

  factory ChannelListResponse.fromJson(Map<String, dynamic> json) {
    return ChannelListResponse(
      channels: (json['channels'] as List<dynamic>?)
              ?.map((e) => MailChannel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channels': channels.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

/// Response for message list
class MessageListResponse {
  final List<MailMessage> messages;
  final int total;
  final int limit;
  final int offset;

  MessageListResponse({
    required this.messages,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => MailMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((e) => e.toJson()).toList(),
      'total': total,
      'limit': limit,
      'offset': offset,
    };
  }
}

/// Response for send message
class SendMessageResponse {
  final int id;
  final bool success;
  final String? message;

  SendMessageResponse({
    required this.id,
    required this.success,
    this.message,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      id: json['id'] as int,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'success': success,
      'message': message,
    };
  }
}
