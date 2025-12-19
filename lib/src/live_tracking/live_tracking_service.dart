import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../events/event_bus.dart';
import '../events/event_types.dart';
import 'models/driver_location.dart';
import 'models/vehicle_position.dart';
import 'models/trip_update.dart';

/// Live tracking service for real-time GPS updates
///
/// Provides:
/// - WebSocket connection to BridgeCore
/// - Live tracking subscription for dispatchers
/// - On-demand location requests
/// - Auto GPS sending for drivers when trip is ongoing
///
/// Usage for Dispatcher:
/// ```dart
/// final tracking = BridgeCore.instance.liveTracking;
///
/// // Connect and subscribe
/// await tracking.connect(userId: dispatcherId);
/// await tracking.subscribeLiveTracking();
///
/// // Listen to vehicle position updates
/// tracking.vehiclePositionStream.listen((position) {
///   updateMapMarker(position);
/// });
///
/// // Request driver location on-demand
/// final location = await tracking.requestDriverLocation(driverId: 5);
/// ```
///
/// Usage for Driver:
/// ```dart
/// final tracking = BridgeCore.instance.liveTracking;
///
/// // Connect
/// await tracking.connect(userId: driverId);
///
/// // Listen for location requests from dispatcher
/// tracking.locationRequestStream.listen((request) async {
///   final position = await getCurrentGpsPosition();
///   tracking.sendLocationResponse(
///     requestId: request.requestId,
///     requesterId: request.requesterId,
///     latitude: position.latitude,
///     longitude: position.longitude,
///   );
/// });
///
/// // Listen to trip updates to start/stop auto tracking
/// tracking.tripUpdateStream.listen((tripUpdate) {
///   if (tripUpdate.isOngoing) {
///     startAutoTracking();
///   } else {
///     stopAutoTracking();
///   }
/// });
/// ```
class LiveTrackingService {
  final String _baseUrl;
  final BridgeCoreEventBus _eventBus;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  int? _userId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Stream controllers for different event types
  final _vehiclePositionController =
      StreamController<VehiclePosition>.broadcast();
  final _tripUpdateController = StreamController<TripUpdate>.broadcast();
  final _locationRequestController =
      StreamController<LocationRequest>.broadcast();
  final _locationResponseController =
      StreamController<DriverLocation>.broadcast();
  final _driverStatusController =
      StreamController<DriverStatusUpdate>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Pending location requests (for awaiting responses)
  final Map<String, Completer<DriverLocation?>> _pendingLocationRequests = {};

  /// Stream of vehicle position updates (from ongoing trips)
  Stream<VehiclePosition> get vehiclePositionStream =>
      _vehiclePositionController.stream;

  /// Stream of trip updates (state changes)
  Stream<TripUpdate> get tripUpdateStream => _tripUpdateController.stream;

  /// Stream of location requests (for drivers)
  Stream<LocationRequest> get locationRequestStream =>
      _locationRequestController.stream;

  /// Stream of location responses (for dispatchers)
  Stream<DriverLocation> get locationResponseStream =>
      _locationResponseController.stream;

  /// Stream of driver status updates
  Stream<DriverStatusUpdate> get driverStatusStream =>
      _driverStatusController.stream;

  /// Stream of connection status changes
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Whether WebSocket is connected
  bool get isConnected => _isConnected;

  LiveTrackingService({
    required String baseUrl,
    required BridgeCoreEventBus eventBus,
  })  : _baseUrl = baseUrl,
        _eventBus = eventBus;

  /// Connect to WebSocket
  ///
  /// [userId] is required for routing messages
  Future<void> connect({required int userId}) async {
    if (_isConnected && _userId == userId) {
      BridgeCoreLogger.debug('Already connected to WebSocket');
      return;
    }

    _userId = userId;

    // Build WebSocket URL properly
    final baseUri = Uri.parse(_baseUrl);

    // Convert HTTP(S) to WS(S), or keep existing WS scheme
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

    // Build WebSocket URI properly using string concatenation
    // to avoid port:0 issue with Uri constructor
    final portPart = baseUri.hasPort ? ':${baseUri.port}' : '';
    final wsUrl = '$wsScheme://${baseUri.host}$portPart/api/v1/ws/$userId';
    final uri = Uri.parse(wsUrl);

    BridgeCoreLogger.info('Connecting to WebSocket: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection
      await _channel!.ready;

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);

      _eventBus.emit(BridgeCoreEventTypes.websocketConnected, {
        'user_id': userId,
        'url': uri.toString(),
      });

      BridgeCoreLogger.info('WebSocket connected');

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
    } catch (e) {
      BridgeCoreLogger.error('WebSocket connection failed: $e');
      _eventBus
          .emit(BridgeCoreEventTypes.websocketError, {'error': e.toString()});
      _scheduleReconnect();
      rethrow;
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionStatusController.add(false);
    _eventBus.emit(BridgeCoreEventTypes.websocketDisconnected, {});
    BridgeCoreLogger.info('WebSocket disconnected');
  }

  /// Subscribe to live tracking channel
  ///
  /// This receives all GPS updates from ongoing trips
  Future<void> subscribeLiveTracking() async {
    _send({
      'type': 'subscribe_live_tracking',
    });
    BridgeCoreLogger.debug('Subscribed to live tracking');
  }

  /// Subscribe to a specific model's events
  Future<void> subscribeToModel(String model) async {
    _send({
      'type': 'subscribe_model_channel',
      'model': model,
    });
    BridgeCoreLogger.debug('Subscribed to model: $model');
  }

  /// Unsubscribe from a model's events
  Future<void> unsubscribeFromModel(String model) async {
    _send({
      'type': 'unsubscribe_model_channel',
      'model': model,
    });
    BridgeCoreLogger.debug('Unsubscribed from model: $model');
  }

  /// Request driver's current location (for dispatchers)
  ///
  /// Returns the driver's location or null if timed out
  Future<DriverLocation?> requestDriverLocation({
    required int driverId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final requestId = const Uuid().v4();

    // Create a completer for this request
    final completer = Completer<DriverLocation?>();
    _pendingLocationRequests[requestId] = completer;

    // Send request
    _send({
      'type': 'request_driver_location',
      'driver_id': driverId,
      'request_id': requestId,
    });

    BridgeCoreLogger.debug('Requested location from driver $driverId');

    // Wait for response with timeout
    try {
      final location = await completer.future.timeout(timeout);
      return location;
    } on TimeoutException {
      BridgeCoreLogger.warning(
          'Location request timed out for driver $driverId');
      _pendingLocationRequests.remove(requestId);
      return null;
    }
  }

  /// Send location response (for drivers)
  ///
  /// Called when driver receives a location request
  void sendLocationResponse({
    required String requestId,
    required int requesterId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) {
    _send({
      'type': 'location_response',
      'request_id': requestId,
      'requester_id': requesterId,
      'latitude': latitude,
      'longitude': longitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    });

    BridgeCoreLogger.debug('Sent location response for request $requestId');
  }

  /// Update driver status (for drivers)
  void updateDriverStatus({
    required DriverStatus status,
    int? vehicleId,
  }) {
    _send({
      'type': 'driver_status_update',
      'status': status.name,
      if (vehicleId != null) 'vehicle_id': vehicleId,
    });

    BridgeCoreLogger.debug('Updated driver status to ${status.name}');
  }

  /// Send ping to keep connection alive
  void ping() {
    _send({
      'type': 'ping',
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Methods
  // ═══════════════════════════════════════════════════════════════════════════

  void _send(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      BridgeCoreLogger.warning('Cannot send message: WebSocket not connected');
      return;
    }

    _channel!.sink.add(jsonEncode(message));
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      _eventBus.emit(BridgeCoreEventTypes.websocketMessage, message);

      switch (type) {
        case 'pong':
          BridgeCoreLogger.debug('Received pong');
          break;

        case 'status':
          BridgeCoreLogger.debug('Status: ${message['message']}');
          break;

        case 'error':
          BridgeCoreLogger.error('WebSocket error: ${message['message']}');
          break;

        case 'webhook_event':
          _handleWebhookEvent(message);
          break;

        case 'request_location':
          // Driver received location request from dispatcher
          final requestId = message['request_id'] as String;
          final requesterId = message['requester_id'] as int;

          _locationRequestController.add(LocationRequest(
            requestId: requestId,
            requesterId: requesterId,
            timestamp: DateTime.now(),
          ));
          break;

        case 'location_response':
          // Dispatcher received location from driver
          final location = DriverLocation.fromJson(message);
          _locationResponseController.add(location);

          // Complete pending request if exists
          final requestId = message['request_id'] as String?;
          if (requestId != null &&
              _pendingLocationRequests.containsKey(requestId)) {
            _pendingLocationRequests[requestId]!.complete(location);
            _pendingLocationRequests.remove(requestId);
          }
          break;

        case 'driver_status':
          _driverStatusController.add(DriverStatusUpdate.fromJson(message));
          break;

        default:
          BridgeCoreLogger.debug('Unknown message type: $type');
      }
    } catch (e) {
      BridgeCoreLogger.error('Error handling WebSocket message: $e');
    }
  }

  void _handleWebhookEvent(Map<String, dynamic> message) {
    final model = message['model'] as String?;
    final data = message['data'] as Map<String, dynamic>? ?? {};

    switch (model) {
      case 'shuttle.vehicle.position':
        final position = VehiclePosition.fromJson(data);
        _vehiclePositionController.add(position);
        BridgeCoreLogger.debug('Vehicle position update: $position');
        break;

      case 'shuttle.trip':
        final tripUpdate = TripUpdate.fromJson(message);
        _tripUpdateController.add(tripUpdate);
        BridgeCoreLogger.debug('Trip update: $tripUpdate');
        break;

      case 'shuttle.gps.position':
        // GPS points for trip history (can be handled similarly)
        BridgeCoreLogger.debug('GPS position update received');
        break;

      default:
        BridgeCoreLogger.debug('Webhook event for model: $model');
    }
  }

  void _handleError(dynamic error) {
    BridgeCoreLogger.error('WebSocket error: $error');
    _eventBus
        .emit(BridgeCoreEventTypes.websocketError, {'error': error.toString()});
    _isConnected = false;
    _connectionStatusController.add(false);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    BridgeCoreLogger.info('WebSocket disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);
    _eventBus.emit(BridgeCoreEventTypes.websocketDisconnected, {});
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      BridgeCoreLogger.error('Max reconnect attempts reached. Giving up.');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    BridgeCoreLogger.info(
        'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _eventBus.emit(BridgeCoreEventTypes.websocketReconnecting, {
      'attempt': _reconnectAttempts,
      'delay_seconds': delay.inSeconds,
    });

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_userId != null) {
        connect(userId: _userId!);
      }
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _vehiclePositionController.close();
    _tripUpdateController.close();
    _locationRequestController.close();
    _locationResponseController.close();
    _driverStatusController.close();
    _connectionStatusController.close();
  }
}

/// Location request from dispatcher
class LocationRequest {
  final String requestId;
  final int requesterId;
  final DateTime timestamp;

  LocationRequest({
    required this.requestId,
    required this.requesterId,
    required this.timestamp,
  });
}

/// Driver status enum
enum DriverStatus {
  online,
  offline,
  busy,
  available,
}

/// Driver status update
class DriverStatusUpdate {
  final int driverId;
  final DriverStatus status;
  final int? vehicleId;
  final DateTime timestamp;

  DriverStatusUpdate({
    required this.driverId,
    required this.status,
    this.vehicleId,
    required this.timestamp,
  });

  factory DriverStatusUpdate.fromJson(Map<String, dynamic> json) {
    return DriverStatusUpdate(
      driverId: json['driver_id'] as int,
      status: DriverStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DriverStatus.offline,
      ),
      vehicleId: json['vehicle_id'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
