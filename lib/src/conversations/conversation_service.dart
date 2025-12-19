import '../client/http_client.dart';
import '../core/endpoints.dart';
import '../core/logger.dart';
import 'models/mail_message.dart';
import 'models/mail_channel.dart';
import 'models/conversation_responses.dart';

/// Conversation Service for Odoo conversations
///
/// Provides methods to:
/// - List and manage channels
/// - Send and receive messages
/// - Access chatter messages on records
/// - Handle direct messages
///
/// Example:
/// ```dart
/// final conversations = BridgeCore.instance.conversations;
///
/// // Get all channels
/// final channels = await conversations.getChannels();
/// print('Channels: ${channels.total}');
///
/// // Get channel messages
/// final messages = await conversations.getChannelMessages(channelId: 123);
///
/// // Send a message
/// final result = await conversations.sendMessage(
///   model: 'mail.channel',
///   resId: 123,
///   body: 'Hello!',
/// );
///
/// // Get chatter for a record
/// final chatter = await conversations.getRecordChatter(
///   model: 'sale.order',
///   recordId: 456,
/// );
/// ```
class ConversationService {
  final BridgeCoreHttpClient httpClient;

  ConversationService({required this.httpClient});

  // ════════════════════════════════════════════════════════════
  // Channel Operations
  // ════════════════════════════════════════════════════════════

  /// Get all channels for current user
  ///
  /// ⚠️ Security: partner_id comes from JWT token automatically
  ///
  /// Example:
  /// ```dart
  /// final channels = await conversations.getChannels();
  /// for (final channel in channels.channels) {
  ///   print('Channel: ${channel.name}');
  /// }
  /// ```
  Future<ChannelListResponse> getChannels() async {
    BridgeCoreLogger.info('Fetching user channels');

    final response = await httpClient.get(
      BridgeCoreEndpoints.conversationChannels,
    );

    return ChannelListResponse.fromJson(response);
  }

  /// Get direct message channels for current user
  ///
  /// ⚠️ Security: partner_id comes from JWT token automatically
  ///
  /// Example:
  /// ```dart
  /// final dms = await conversations.getDirectMessages();
  /// for (final dm in dms.channels) {
  ///   print('DM: ${dm.name}');
  /// }
  /// ```
  Future<ChannelListResponse> getDirectMessages() async {
    BridgeCoreLogger.info('Fetching direct messages');

    final response = await httpClient.get(
      BridgeCoreEndpoints.conversationDirectMessages,
    );

    return ChannelListResponse.fromJson(response);
  }

  // ════════════════════════════════════════════════════════════
  // Message Operations
  // ════════════════════════════════════════════════════════════

  /// Get messages in a channel
  ///
  /// Example:
  /// ```dart
  /// final messages = await conversations.getChannelMessages(
  ///   channelId: 123,
  ///   limit: 50,
  ///   offset: 0,
  /// );
  /// ```
  Future<MessageListResponse> getChannelMessages({
    required int channelId,
    int limit = 50,
    int offset = 0,
  }) async {
    BridgeCoreLogger.info('Fetching messages for channel $channelId');

    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await httpClient.get(
      '${BridgeCoreEndpoints.conversationChannelMessages(channelId)}?$queryString',
    );

    return MessageListResponse.fromJson(response);
  }

  /// Get chatter messages for a record
  ///
  /// Example:
  /// ```dart
  /// final chatter = await conversations.getRecordChatter(
  ///   model: 'sale.order',
  ///   recordId: 456,
  ///   limit: 50,
  /// );
  /// ```
  Future<MessageListResponse> getRecordChatter({
    required String model,
    required int recordId,
    int limit = 50,
  }) async {
    BridgeCoreLogger.info('Fetching chatter for $model:$recordId');

    final queryParams = <String, dynamic>{
      'limit': limit,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final response = await httpClient.get(
      '${BridgeCoreEndpoints.conversationChatter(model, recordId)}?$queryString',
    );

    return MessageListResponse.fromJson(response);
  }

  /// Send a message
  ///
  /// ⚠️ Security: author_id comes from JWT session automatically, not from request
  ///
  /// Example:
  /// ```dart
  /// // Send message to channel
  /// final result = await conversations.sendMessage(
  ///   model: 'mail.channel',
  ///   resId: 123,
  ///   body: '<p>Hello everyone!</p>',
  ///   partnerIds: [1, 2, 3], // Optional: specific recipients
  /// );
  ///
  /// // Send message to chatter (sale.order, etc.)
  /// final result = await conversations.sendMessage(
  ///   model: 'sale.order',
  ///   resId: 456,
  ///   body: '<p>This order looks good!</p>',
  /// );
  ///
  /// // Reply to a message
  /// final result = await conversations.sendMessage(
  ///   model: 'mail.channel',
  ///   resId: 123,
  ///   body: '<p>Reply message</p>',
  ///   parentId: 789, // Parent message ID
  /// );
  /// ```
  Future<SendMessageResponse> sendMessage({
    required String model,
    required int resId,
    required String body,
    List<int>? partnerIds,
    String? subject,
    int? parentId,
  }) async {
    BridgeCoreLogger.info('Sending message to $model:$resId');

    final response = await httpClient.post(
      BridgeCoreEndpoints.conversationSendMessage,
      {
        'model': model,
        'res_id': resId,
        'body': body,
        if (partnerIds != null) 'partner_ids': partnerIds,
        if (subject != null) 'subject': subject,
        if (parentId != null) 'parent_id': parentId,
      },
    );

    return SendMessageResponse.fromJson(response);
  }
}
