import 'dart:collection';

/// Metrics collector for BridgeCore SDK
class BridgeCoreMetrics {
  static final BridgeCoreMetrics _instance = BridgeCoreMetrics._internal();
  factory BridgeCoreMetrics() => _instance;
  BridgeCoreMetrics._internal();

  final Map<String, _RequestMetric> _requests = {};
  final Queue<_RequestMetric> _recentRequests = Queue();
  static const int maxRecentRequests = 100;

  /// Record request start
  void recordRequestStart(String endpoint, String method) {
    final key = '${method}_$endpoint';
    _requests[key] = _RequestMetric(
      endpoint: endpoint,
      method: method,
      startTime: DateTime.now(),
    );
  }

  /// Record request end
  void recordRequestEnd(String endpoint, String method,
      {bool success = true, int? statusCode, String? error}) {
    final key = '${method}_$endpoint';
    final metric = _requests[key];
    if (metric == null) return;

    final duration = DateTime.now().difference(metric.startTime);
    metric.endTime = DateTime.now();
    metric.duration = duration;
    metric.success = success;
    metric.statusCode = statusCode;
    metric.error = error;

    // Add to recent requests
    _recentRequests.add(metric);
    if (_recentRequests.length > maxRecentRequests) {
      _recentRequests.removeFirst();
    }
  }

  /// Get metrics summary
  Map<String, dynamic> getSummary() {
    final successful = _recentRequests.where((r) => r.success == true).length;
    final failed = _recentRequests.where((r) => r.success == false).length;
    final total = _recentRequests.length;

    if (total == 0) {
      return {
        'total_requests': 0,
        'successful_requests': 0,
        'failed_requests': 0,
        'success_rate': 0.0,
        'average_duration_ms': 0.0,
      };
    }

    final durations = _recentRequests
        .where((r) => r.duration != null)
        .map((r) => r.duration!.inMilliseconds)
        .toList();

    final avgDuration = durations.isEmpty
        ? 0.0
        : durations.reduce((a, b) => a + b) / durations.length;

    return {
      'total_requests': total,
      'successful_requests': successful,
      'failed_requests': failed,
      'success_rate': total > 0 ? (successful / total) : 0.0,
      'average_duration_ms': avgDuration,
      'recent_requests':
          _recentRequests.take(10).map((r) => r.toMap()).toList(),
    };
  }

  /// Get endpoint statistics
  Map<String, Map<String, dynamic>> getEndpointStats() {
    final Map<String, List<_RequestMetric>> grouped = {};

    for (final request in _recentRequests) {
      final key = '${request.method}_${request.endpoint}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(request);
    }

    final stats = <String, Map<String, dynamic>>{};

    grouped.forEach((key, requests) {
      final successful = requests.where((r) => r.success == true).length;
      final durations = requests
          .where((r) => r.duration != null)
          .map((r) => r.duration!.inMilliseconds)
          .toList();

      stats[key] = {
        'total': requests.length,
        'successful': successful,
        'failed': requests.length - successful,
        'success_rate':
            requests.isNotEmpty ? (successful / requests.length) : 0.0,
        'average_duration_ms': durations.isEmpty
            ? 0.0
            : durations.reduce((a, b) => a + b) / durations.length,
      };
    });

    return stats;
  }

  /// Clear all metrics
  void clear() {
    _requests.clear();
    _recentRequests.clear();
  }
}

class _RequestMetric {
  final String endpoint;
  final String method;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  bool? success;
  int? statusCode;
  String? error;

  _RequestMetric({
    required this.endpoint,
    required this.method,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'endpoint': endpoint,
      'method': method,
      'duration_ms': duration?.inMilliseconds,
      'success': success,
      'status_code': statusCode,
      'error': error,
    };
  }
}
