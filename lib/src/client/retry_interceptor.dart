import 'package:dio/dio.dart';
import '../core/logger.dart';

/// Retry interceptor for handling transient failures
/// 
/// Automatically retries failed requests based on:
/// - HTTP status codes (5xx server errors)
/// - Connection errors
/// - Timeout errors
/// 
/// NOTE: Retries are limited to avoid overwhelming the server during outages.
/// For 429 (rate limit) errors, we don't retry to avoid making things worse.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryableStatusCodes;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2, // Reduced from 3 to avoid overwhelming server
    this.retryDelay = const Duration(seconds: 3), // Increased from 2s
    this.retryableStatusCodes = const [503, 504], // Removed 500, 502 - these often indicate server overload
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Get retry count from request options
    final attempt = err.requestOptions.extra['retry_attempt'] as int? ?? 0;

    // Check if we should retry
    if (attempt >= maxRetries) {
      // Max retries exceeded
      return handler.next(err);
    }

    // Check if error is retryable
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    // Calculate delay with exponential backoff
    final delay = retryDelay * (attempt + 1);

    BridgeCoreLogger.debug(
      'Retry attempt ${attempt + 1}/$maxRetries after ${delay.inSeconds}s for ${err.requestOptions.uri}',
    );

    // Wait before retry
    await Future.delayed(delay);

    // Increment retry count
    err.requestOptions.extra['retry_attempt'] = attempt + 1;

    try {
      // Retry the request
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      // Retry failed, pass to next interceptor
      return handler.next(e);
    }
  }

  /// Check if error should be retried
  bool _shouldRetry(DioException err) {
    // NEVER retry on rate limit errors - this will make things worse
    if (err.response?.statusCode == 429) {
      return false;
    }
    
    // Don't retry on 500/502 - these often indicate server overload
    // Retrying will just make the problem worse
    if (err.response?.statusCode == 500 || err.response?.statusCode == 502) {
      return false;
    }

    // Retry on connection errors (network issues, not server issues)
    if (err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Retry on specific status codes (503, 504 only - temporary unavailability)
    if (err.response != null &&
        retryableStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }

    // Don't retry on other errors
    return false;
  }
}
