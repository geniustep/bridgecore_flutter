import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';
import 'models/mail_message.dart';
import 'models/mail_channel.dart';

/// Conversation WebSocket Service for real-time messaging
///
/// Provides:
/// - WebSocket connection to BridgeCore conversations
/// - Real-time message updates via WebSocket
/// - Channel subscription management
///
/// ⚠️ Security: Authentication via JWT token in query parameter
///
/// Usage:
/// ```dart
/// final ws = BridgeCore.instance.conversationsWebSocket;
///
/// // Connect (token comes from TokenManager)
/// await ws.connect(token: accessToken);
///
/// // Subscribe to channel
/// await ws.subscribeChannel(channelId: 123);
///
/// // Listen for new messages
/// ws.messageStream.listen((message) {
///   print('New message: ${message.body}');
/// });
///
/// // Send message (via REST API)
/// await BridgeCore.instance.conversations.sendMessage(...);
/// ```
class ConversationWebSocketService {
  final String _baseUrl;
  final BridgeCoreEventBus _eventBus = BridgeCoreEventBus.instance;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _lastToken;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Stream controllers
  final _messageController = StreamController<MailMessage>.broadcast();
  final _channelUpdateController = StreamController<MailChannel>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final Set<int> _subscribedChannels = {};

  /// Stream of incoming messages
  Stream<MailMessage> get messageStream => _messageController.stream;

  /// Stream of channel updates
  Stream<MailChannel> get channelUpdateStream => _channelUpdateController.stream;

  /// Stream of connection status changes
  Stream<bool> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Whether WebSocket is currently connected
  bool get isConnected => _isConnected;

  /// List of subscribed channel IDs
  List<int> get subscribedChannels => _subscribedChannels.toList();

  ConversationWebSocketService({required String baseUrl}) {
    // Store base URL - will convert to WS URL in connect()
    _baseUrl = baseUrl;
  }

  /// Connect to conversation WebSocket
  ///
  /// ⚠️ Security: token should come from TokenManager, not user input
  ///
  /// Example:
  /// ```dart
  /// final token = BridgeCore.instance.auth.tokenManager.getAccessToken();
  /// await ws.connect(token: token);
  /// ```
  Future<void> connect({required String token}) async {
    if (_isConnected) {
      BridgeCoreLogger.warning('WebSocket already connected');
      return;
    }

    try {
      // Build WebSocket URL properly (like LiveTrackingService)
      final baseUri = Uri.parse(_baseUrl);
      
      // Convert HTTP(S) to WS(S)
      final String wsScheme;
      switch (baseUri.scheme) {
        case 'https':
        case 'wss':
          wsScheme = 'wss';
          break;
        case 'http':
        case 'ws':
        default:
          wsScheme = 'ws';
          break;
      }
      
      // Build WebSocket URI
      final portPart = baseUri.hasPort ? ':${baseUri.port}' : '';
      final wsUrl = '$wsScheme://${baseUri.host}$portPart/ws/conversations?token=$token';
      final uri = Uri.parse(wsUrl);
      
      BridgeCoreLogger.info('Connecting to conversation WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);
      
      // Wait for connection (similar to LiveTrackingService)
      await _channel!.ready;
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _lastToken = token;

      _connectionStatusController.add(true);

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      BridgeCoreLogger.info('Conversation WebSocket connected');
      _eventBus.emit(BridgeCoreEventTypes.webhookReceived, {
        'type': 'conversation_ws_connected',
        'status': 'connected',
      });
    } catch (e) {
      BridgeCoreLogger.error('Failed to connect conversation WebSocket: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
      _scheduleReconnect(token);
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    if (!_isConnected) return;

    BridgeCoreLogger.info('Disconnecting conversation WebSocket...');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _lastToken = null;

    await _subscription?.cancel();
    await _channel?.sink.close();

    _isConnected = false;
    _subscribedChannels.clear();
    _connectionStatusController.add(false);

    BridgeCoreLogger.info('Conversation WebSocket disconnected');
  }

  /// Subscribe to a channel for real-time messages
  ///
  /// Example:
  /// ```dart
  /// await ws.subscribeChannel(channelId: 123);
  /// ```
  Future<void> subscribeChannel({required int channelId}) async {
    if (!_isConnected) {
      throw Exception('WebSocket not connected. Call connect() first.');
    }

    try {
      _channel?.sink.add(jsonEncode({
        'action': 'subscribe_channel',
        'channel_id': channelId,
      }));

      _subscribedChannels.add(channelId);
      BridgeCoreLogger.info('Subscribed to channel $channelId');
    } catch (e) {
      BridgeCoreLogger.error('Failed to subscribe to channel $channelId: $e');
      rethrow;
    }
  }

  /// Unsubscribe from a channel
  ///
  /// Example:
  /// ```dart
  /// await ws.unsubscribeChannel(channelId: 123);
  /// ```
  Future<void> unsubscribeChannel({required int channelId}) async {
    if (!_isConnected) {
      BridgeCoreLogger.warning('WebSocket not connected');
      return;
    }

    try {
      _channel?.sink.add(jsonEncode({
        'action': 'unsubscribe_channel',
        'channel_id': channelId,
      }));

      _subscribedChannels.remove(channelId);
      BridgeCoreLogger.info('Unsubscribed from channel $channelId');
    } catch (e) {
      BridgeCoreLogger.error('Failed to unsubscribe from channel $channelId: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'channel_message':
          _handleChannelMessage(data);
          break;
        case 'chatter_message':
          _handleChatterMessage(data);
          break;
        case 'thread_message':
          _handleThreadMessage(data);
          break;
        case 'channel_updated':
          _handleChannelUpdated(data);
          break;
        case 'subscribed':
        case 'unsubscribed':
          // Acknowledgment messages
          BridgeCoreLogger.debug('WebSocket action: $type');
          break;
        default:
          BridgeCoreLogger.warning('Unknown message type: $type');
      }
    } catch (e) {
      BridgeCoreLogger.error('Error handling WebSocket message: $e');
    }
  }

  void _handleChannelMessage(Map<String, dynamic> data) {
    final messageData = data['message'] as Map<String, dynamic>?;
    if (messageData != null) {
      try {
        final message = MailMessage.fromJson(messageData);
        _messageController.add(message);

        // Emit event
        _eventBus.emit(BridgeCoreEventTypes.webhookReceived, {
          'type': 'channel_message',
          'channel_id': data['channel_id'],
          'message': message.toJson(),
        });

        BridgeCoreLogger.debug(
            'Received channel message: ${message.id} in channel ${data['channel_id']}');
      } catch (e) {
        BridgeCoreLogger.error('Error parsing channel message: $e');
      }
    }
  }

  void _handleChatterMessage(Map<String, dynamic> data) {
    final messageData = data['message'] as Map<String, dynamic>?;
    if (messageData != null) {
      try {
        final message = MailMessage.fromJson(messageData);
        _messageController.add(message);

        // Emit event
        _eventBus.emit(BridgeCoreEventTypes.webhookReceived, {
          'type': 'chatter_message',
          'model': data['model'],
          'res_id': data['res_id'],
          'message': message.toJson(),
        });

        BridgeCoreLogger.debug(
            'Received chatter message: ${message.id} on ${data['model']}:${data['res_id']}');
      } catch (e) {
        BridgeCoreLogger.error('Error parsing chatter message: $e');
      }
    }
  }

  void _handleThreadMessage(Map<String, dynamic> data) {
    // Similar to chatter message
    _handleChatterMessage(data);
  }

  void _handleChannelUpdated(Map<String, dynamic> data) {
    try {
      final channelData = data['data'] as Map<String, dynamic>?;
      if (channelData != null) {
        final channel = MailChannel.fromJson(channelData);
        _channelUpdateController.add(channel);

        // Emit event
        _eventBus.emit(BridgeCoreEventTypes.webhookReceived, {
          'type': 'channel_updated',
          'channel_id': data['channel_id'],
          'channel': channel.toJson(),
        });

        BridgeCoreLogger.debug('Channel updated: ${channel.id}');
      }
    } catch (e) {
      BridgeCoreLogger.error('Error parsing channel update: $e');
    }
  }

  void _handleError(dynamic error) {
    BridgeCoreLogger.error('WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    
    // Schedule reconnect if we have a token
    if (_lastToken != null) {
      _scheduleReconnect(_lastToken!);
    }
  }

  void _handleDisconnect() {
    BridgeCoreLogger.info('WebSocket disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);

    _eventBus.emit(BridgeCoreEventTypes.webhookReceived, {
      'type': 'conversation_ws_disconnected',
      'status': 'disconnected',
    });
    
    // Schedule reconnect if we have a token
    if (_lastToken != null) {
      _scheduleReconnect(_lastToken!);
    }
  }

  void _scheduleReconnect(String token) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      BridgeCoreLogger.error(
          'Max reconnection attempts reached for conversation WebSocket');
      return;
    }

    _reconnectAttempts++;
    BridgeCoreLogger.info(
        'Scheduling reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts');

    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      connect(token: token);
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _channelUpdateController.close();
    _connectionStatusController.close();
  }
}
