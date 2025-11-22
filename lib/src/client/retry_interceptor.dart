import 'package:dio/dio.dart';
import '../core/logger.dart';

/// Retry interceptor for handling transient failures
/// 
/// Automatically retries failed requests based on:
/// - HTTP status codes (5xx server errors)
/// - Connection errors
/// - Timeout errors
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryableStatusCodes;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.retryableStatusCodes = const [500, 502, 503, 504],
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
    // Retry on connection errors
    if (err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Retry on specific status codes
    if (err.response != null &&
        retryableStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }

    // Don't retry on other errors
    return false;
  }
}
