import 'dart:async';
import 'bridgecore_event.dart';
import '../core/logger.dart';

/// BridgeCore Event Bus
///
/// Central event bus for all events in the system.
/// Uses a broadcast stream controller to allow multiple listeners.
///
/// Usage:
/// ```dart
/// // Get instance
/// final eventBus = BridgeCoreEventBus.instance;
///
/// // Emit event
/// eventBus.emit('auth.login', {'user_id': 123});
///
/// // Listen to specific event type
/// eventBus.on('auth.login').listen((event) {
///   print('User logged in: ${event.data['user_id']}');
/// });
///
/// // Listen to all events
/// eventBus.stream.listen((event) {
///   print('Event: ${event.type}');
/// });
/// ```
class BridgeCoreEventBus {
  static final BridgeCoreEventBus _instance = BridgeCoreEventBus._internal();

  /// Get singleton instance
  static BridgeCoreEventBus get instance => _instance;

  /// Broadcast stream controller for events
  final StreamController<BridgeCoreEvent> _controller =
      StreamController<BridgeCoreEvent>.broadcast();

  /// Event history (optional, for debugging)
  final List<BridgeCoreEvent> _history = [];

  /// Maximum history size
  static const int _maxHistorySize = 100;

  /// Event filters (for conditional event processing)
  final Map<String, bool Function(BridgeCoreEvent)> _filters = {};

  /// Event interceptors (for event modification before emission)
  final List<BridgeCoreEvent Function(BridgeCoreEvent)> _interceptors = [];

  /// Statistics
  final Map<String, int> _eventCounts = {};
  int _totalEventsEmitted = 0;

  BridgeCoreEventBus._internal();

  /// Get the main event stream
  Stream<BridgeCoreEvent> get stream => _controller.stream;

  /// Emit an event
  ///
  /// Example:
  /// ```dart
  /// eventBus.emit('auth.login', {'user_id': 123, 'username': 'john'});
  /// ```
  void emit(String type, Map<String, dynamic> data, {String? source}) {
    var event = BridgeCoreEvent(
      type: type,
      data: data,
      source: source,
      id: _generateEventId(),
    );

    // Apply interceptors
    for (final interceptor in _interceptors) {
      event = interceptor(event);
    }

    // Apply filters
    final filter = _filters[type];
    if (filter != null && !filter(event)) {
      BridgeCoreLogger.debug('Event filtered: $type');
      return;
    }

    // Add to controller
    _controller.add(event);

    // Update statistics
    _totalEventsEmitted++;
    _eventCounts[type] = (_eventCounts[type] ?? 0) + 1;

    // Add to history
    _addToHistory(event);

    // Log event
    BridgeCoreLogger.debug('Event emitted: $type', data);
  }

  /// Emit an event object
  void emitEvent(BridgeCoreEvent event) {
    emit(event.type, event.data, source: event.source);
  }

  /// Listen to specific event type
  ///
  /// Example:
  /// ```dart
  /// eventBus.on('auth.login').listen((event) {
  ///   print('User: ${event.data['username']}');
  /// });
  /// ```
  Stream<BridgeCoreEvent> on(String eventType) {
    return stream.where((event) => event.type == eventType);
  }

  /// Listen to multiple event types
  ///
  /// Example:
  /// ```dart
  /// eventBus.onAny(['auth.login', 'auth.logout']).listen((event) {
  ///   print('Auth event: ${event.type}');
  /// });
  /// ```
  Stream<BridgeCoreEvent> onAny(List<String> eventTypes) {
    return stream.where((event) => eventTypes.contains(event.type));
  }

  /// Listen to events with a pattern (starts with)
  ///
  /// Example:
  /// ```dart
  /// // Listen to all auth events
  /// eventBus.onPattern('auth.').listen((event) {
  ///   print('Auth event: ${event.type}');
  /// });
  /// ```
  Stream<BridgeCoreEvent> onPattern(String pattern) {
    return stream.where((event) => event.type.startsWith(pattern));
  }

  /// Add event filter
  ///
  /// Filters can prevent events from being emitted
  ///
  /// Example:
  /// ```dart
  /// eventBus.addFilter('odoo.record_created', (event) {
  ///   // Only emit if model is 'sale.order'
  ///   return event.data['model'] == 'sale.order';
  /// });
  /// ```
  void addFilter(String eventType, bool Function(BridgeCoreEvent) filter) {
    _filters[eventType] = filter;
  }

  /// Remove event filter
  void removeFilter(String eventType) {
    _filters.remove(eventType);
  }

  /// Add event interceptor
  ///
  /// Interceptors can modify events before emission
  ///
  /// Example:
  /// ```dart
  /// eventBus.addInterceptor((event) {
  ///   // Add timestamp to all events
  ///   return BridgeCoreEvent(
  ///     type: event.type,
  ///     data: {...event.data, 'intercepted_at': DateTime.now()},
  ///   );
  /// });
  /// ```
  void addInterceptor(BridgeCoreEvent Function(BridgeCoreEvent) interceptor) {
    _interceptors.add(interceptor);
  }

  /// Remove all interceptors
  void clearInterceptors() {
    _interceptors.clear();
  }

  /// Get event history
  List<BridgeCoreEvent> get history => List.unmodifiable(_history);

  /// Get event statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_events': _totalEventsEmitted,
      'event_counts': Map<String, int>.from(_eventCounts),
      'history_size': _history.length,
      'active_filters': _filters.length,
      'active_interceptors': _interceptors.length,
    };
  }

  /// Get count for specific event type
  int getEventCount(String eventType) {
    return _eventCounts[eventType] ?? 0;
  }

  /// Clear event history
  void clearHistory() {
    _history.clear();
    BridgeCoreLogger.debug('Event history cleared');
  }

  /// Clear all statistics
  void clearStatistics() {
    _eventCounts.clear();
    _totalEventsEmitted = 0;
    BridgeCoreLogger.debug('Event statistics cleared');
  }

  /// Reset event bus (clear filters, interceptors, history, stats)
  void reset() {
    _filters.clear();
    _interceptors.clear();
    clearHistory();
    clearStatistics();
    BridgeCoreLogger.debug('Event bus reset');
  }

  /// Dispose of the event bus
  void dispose() {
    _controller.close();
    reset();
  }

  /// Add event to history
  void _addToHistory(BridgeCoreEvent event) {
    _history.add(event);

    // Keep history size limited
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// Generate unique event ID
  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_totalEventsEmitted}';
  }

  /// Wait for specific event (returns Future that completes on first match)
  ///
  /// Example:
  /// ```dart
  /// final event = await eventBus.waitFor('auth.login', timeout: Duration(seconds: 5));
  /// print('Login completed: ${event.data}');
  /// ```
  Future<BridgeCoreEvent> waitFor(
    String eventType, {
    Duration? timeout,
    bool Function(BridgeCoreEvent)? condition,
  }) async {
    final completer = Completer<BridgeCoreEvent>();
    StreamSubscription<BridgeCoreEvent>? subscription;

    subscription = on(eventType).listen((event) {
      if (condition == null || condition(event)) {
        if (!completer.isCompleted) {
          completer.complete(event);
          subscription?.cancel();
        }
      }
    });

    if (timeout != null) {
      return completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription?.cancel();
          throw TimeoutException(
            'Timeout waiting for event: $eventType',
            timeout,
          );
        },
      );
    }

    return completer.future;
  }

  /// Emit event and wait for response event
  ///
  /// Useful for request-response patterns
  ///
  /// Example:
  /// ```dart
  /// final response = await eventBus.emitAndWait(
  ///   'sync.start',
  ///   {},
  ///   responseType: 'sync.completed',
  ///   timeout: Duration(seconds: 30),
  /// );
  /// ```
  Future<BridgeCoreEvent> emitAndWait(
    String eventType,
    Map<String, dynamic> data, {
    required String responseType,
    Duration? timeout,
    bool Function(BridgeCoreEvent)? responseCondition,
  }) async {
    final responseFuture = waitFor(
      responseType,
      timeout: timeout,
      condition: responseCondition,
    );

    emit(eventType, data);

    return responseFuture;
  }
}
