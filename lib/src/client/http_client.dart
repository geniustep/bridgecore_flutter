import 'package:dio/dio.dart';
import '../auth/token_manager.dart';
import '../core/exceptions.dart';
import '../core/endpoints.dart';
import '../core/cache_manager.dart';
import '../core/metrics.dart';
import '../core/logger.dart';
import 'retry_interceptor.dart';

/// HTTP client for BridgeCore API using Dio
class BridgeCoreHttpClient {
  final String baseUrl;
  final TokenManager tokenManager;
  late final Dio _dio;
  bool _retryEnabled;
  int _maxRetries;
  final CacheManager _cache = CacheManager();
  final BridgeCoreMetrics _metrics = BridgeCoreMetrics();
  bool _cacheEnabled = false;

  BridgeCoreHttpClient({
    required this.baseUrl,
    required this.tokenManager,
    bool debugMode = false,
    Duration timeout = const Duration(seconds: 30),
    bool enableRetry = true,
    int maxRetries = 3,
    bool enableCache = false,
  })  : _retryEnabled = enableRetry,
        _maxRetries = maxRetries,
        _cacheEnabled = enableCache {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add retry interceptor (before auth interceptor)
    if (_retryEnabled) {
      _dio.interceptors.add(
        RetryInterceptor(
          dio: _dio,
          maxRetries: _maxRetries,
          retryDelay: const Duration(seconds: 2),
        ),
      );
    }

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to requests
          final token = await tokenManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (debugMode) {
            BridgeCoreLogger.debug('${options.method} ${options.uri}');
            if (options.data != null) {
              BridgeCoreLogger.debug('Request Body', options.data);
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (debugMode) {
            BridgeCoreLogger.debug(
              'Response ${response.statusCode}',
              response.data,
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (debugMode) {
            BridgeCoreLogger.error(
                'Request error: ${error.message}', null, error);
          }

          // Auto token refresh on 401
          if (error.response?.statusCode == 401) {
            try {
              await _refreshToken();

              // Retry original request
              final options = error.requestOptions;
              final token = await tokenManager.getAccessToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Add logging in debug mode
    if (debugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  /// Refresh token
  Future<void> _refreshToken() async {
    final refreshToken = await tokenManager.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    try {
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      refreshDio.options.headers['Authorization'] = 'Bearer $refreshToken';

      final response =
          await refreshDio.post(BridgeCoreEndpoints.refresh, data: {});

      final newAccessToken = response.data['access_token'] as String;
      await tokenManager.saveTokens(newAccessToken, refreshToken);
    } catch (e) {
      await tokenManager.clearTokens();
      rethrow;
    }
  }

  void setCustomHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  void setTimeout(Duration timeout) {
    _dio.options.connectTimeout = timeout;
    _dio.options.receiveTimeout = timeout;
  }

  void setDebugMode(bool enabled) {
    // Handled via interceptors
  }

  /// Enable or disable retry interceptor
  void setRetryEnabled(bool enabled) {
    _retryEnabled = enabled;
  }

  /// Set max retries
  void setMaxRetries(int maxRetries) {
    _maxRetries = maxRetries;
  }

  /// Enable or disable cache
  void setCacheEnabled(bool enabled) {
    _cacheEnabled = enabled;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cache.getStats();
  }

  /// Get metrics summary
  Map<String, dynamic> getMetrics() {
    return _metrics.getSummary();
  }

  /// Get endpoint statistics
  Map<String, Map<String, dynamic>> getEndpointStats() {
    return _metrics.getEndpointStats();
  }

  Never _handleError(DioException error) {
    final statusCode = error.response?.statusCode;
    final requestOptions = error.requestOptions;
    String message;
    Map<String, dynamic>? details;

    try {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['detail'] as String? ??
            data['message'] as String? ??
            'Request failed';
        details = data;
      } else if (data is String) {
        message = data.isNotEmpty ? data : (error.message ?? 'Request failed');
      } else {
        message = error.message ?? 'Request failed';
      }
    } catch (_) {
      message = error.message ?? 'Request failed';
    }

    // Record failed request
    _metrics.recordRequestEnd(
      requestOptions.path,
      requestOptions.method,
      success: false,
      statusCode: statusCode,
      error: message,
    );

    // Log error
    BridgeCoreLogger.error(
      'Request failed: $message',
      {
        'endpoint': requestOptions.path,
        'method': requestOptions.method,
        'status_code': statusCode,
      },
      error,
    );

    switch (statusCode) {
      case 401:
        throw UnauthorizedException(
          message,
          statusCode: statusCode,
          endpoint: requestOptions.path,
          method: requestOptions.method,
          details: details,
          originalError: error,
        );
      case 403:
        if (message.toLowerCase().contains('suspend')) {
          throw TenantSuspendedException(
            message,
            statusCode: statusCode,
            endpoint: requestOptions.path,
            method: requestOptions.method,
            details: details,
            originalError: error,
          );
        }
        throw ForbiddenException(
          message,
          statusCode: statusCode,
          endpoint: requestOptions.path,
          method: requestOptions.method,
          details: details,
          originalError: error,
        );
      case 404:
        throw NotFoundException(
          message,
          statusCode: statusCode,
          endpoint: requestOptions.path,
          method: requestOptions.method,
          details: details,
          originalError: error,
        );
      case 400:
        throw ValidationException(
          message,
          statusCode: statusCode,
          endpoint: requestOptions.path,
          method: requestOptions.method,
          details: details,
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
        throw ServerException(
          message,
          statusCode: statusCode,
          endpoint: requestOptions.path,
          method: requestOptions.method,
          details: details,
          originalError: error,
        );
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          throw NetworkException(
            'Timeout: $message',
            originalError: error,
            endpoint: requestOptions.path,
            method: requestOptions.method,
            details: details,
          );
        }
        if (error.type == DioExceptionType.connectionError) {
          throw NetworkException(
            'Connection error: $message',
            originalError: error,
            endpoint: requestOptions.path,
            method: requestOptions.method,
            details: details,
          );
        }
        throw BridgeCoreException(
          message,
          statusCode: statusCode,
          endpoint: requestOptions.path,
          method: requestOptions.method,
          details: details,
          originalError: error,
        );
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    bool useCache = false,
    Duration? cacheTTL,
  }) async {
    // Check cache for GET-like operations (if implemented)
    final cacheKey =
        (useCache && _cacheEnabled) ? 'POST_${path}_${body.toString()}' : null;
    if (cacheKey != null) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        BridgeCoreLogger.debug('Cache hit for $path');
        return cached;
      }
    }

    // Record request start
    _metrics.recordRequestStart(path, 'POST');
    BridgeCoreLogger.debug('POST $path', body);

    try {
      final response = await _dio.post(path, data: body);
      final data = response.data as Map<String, dynamic>;

      // Record success
      _metrics.recordRequestEnd(
        path,
        'POST',
        success: true,
        statusCode: response.statusCode,
      );

      // Cache response if enabled
      if (useCache && _cacheEnabled && cacheKey != null) {
        _cache.set(cacheKey, data, ttl: cacheTTL);
      }

      return data;
    } on DioException catch (e) {
      _handleError(e);
    } catch (e) {
      _metrics.recordRequestEnd(path, 'POST',
          success: false, error: e.toString());
      throw NetworkException('Network error: $e', originalError: e);
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    bool useCache = false,
    Duration? cacheTTL,
  }) async {
    // Check cache
    final cacheKey = (useCache && _cacheEnabled)
        ? 'GET_${path}_${queryParams?.toString()}'
        : null;
    if (cacheKey != null) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        BridgeCoreLogger.debug('Cache hit for $path');
        return cached;
      }
    }

    // Record request start
    _metrics.recordRequestStart(path, 'GET');
    BridgeCoreLogger.debug('GET $path', queryParams);

    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;

      // Record success
      _metrics.recordRequestEnd(
        path,
        'GET',
        success: true,
        statusCode: response.statusCode,
      );

      // Cache response if enabled
      if (useCache && _cacheEnabled && cacheKey != null) {
        _cache.set(cacheKey, data, ttl: cacheTTL);
      }

      return data;
    } on DioException catch (e) {
      _handleError(e);
    } catch (e) {
      _metrics.recordRequestEnd(path, 'GET',
          success: false, error: e.toString());
      throw NetworkException('Network error: $e', originalError: e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await _dio.put(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
    } catch (e) {
      throw NetworkException('Network error: $e', originalError: e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await _dio.delete(path);
      if (response.data == null || response.data == '') {
        return {};
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
    } catch (e) {
      throw NetworkException('Network error: $e', originalError: e);
    }
  }

  /// Upload file with progress (Bonus feature with Dio!)
  Future<Map<String, dynamic>> upload(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
    } catch (e) {
      throw NetworkException('Upload error: $e', originalError: e);
    }
  }

  /// Download file with progress (Bonus feature with Dio!)
  Future<void> download(
    String path,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await _dio.download(path, savePath, onReceiveProgress: onProgress);
    } on DioException catch (e) {
      _handleError(e);
    } catch (e) {
      throw NetworkException('Download error: $e', originalError: e);
    }
  }

  /// Create cancel token for request cancellation (Bonus!)
  CancelToken createCancelToken() {
    return CancelToken();
  }
}
