import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Enterprise-grade API client with automatic token refresh and error handling
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  static String get _baseUrl {
    // 1. Get URL from env or default
    String url = dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api/v1';

    // 2. Platform-specific fix for Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      // If we are on Android and the config says localhost, we MUST use 10.0.2.2
      // to reach the host machine.
      if (url.contains('localhost')) {
        url = url.replaceFirst('localhost', '10.0.2.2');
      }
    }

    return url;
  }

  ApiClient(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor - Add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          developer.log(
            'REQUEST[${options.method}] => PATH: ${options.path}',
            name: 'ApiClient',
          );

          // Add access token to request headers
          final token = await _storage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add correlation ID for request tracing
          options.headers['X-Request-ID'] = DateTime.now().millisecondsSinceEpoch.toString();

          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          developer.log(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
            name: 'ApiClient',
            error: error,
          );
          developer.log(
            'Message: ${error.message}',
            name: 'ApiClient',
          );
          developer.log(
            'Data: ${error.response?.data}',
            name: 'ApiClient',
          );

          // Handle 401 Unauthorized - Try to refresh token
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            developer.log('Token expired, attempting refresh...', name: 'ApiClient');
            
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the failed request with new token
              developer.log('Token refreshed, retrying request', name: 'ApiClient');
              return _retry(error.requestOptions, handler);
            } else {
              developer.log('Token refresh failed, clearing session', name: 'ApiClient');
              await _clearSession();
            }
          }

          // Handle network errors with retry
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            developer.log('Network timeout, consider retry', name: 'ApiClient');
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Attempt to refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      developer.log('Already refreshing token, skipping...', name: 'ApiClient');
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        developer.log('No refresh token available', name: 'ApiClient');
        _isRefreshing = false;
        return false;
      }

      // Call refresh endpoint
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      // Save new tokens
      await _storage.write(key: 'access_token', value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }

      developer.log('Token refresh successful', name: 'ApiClient');
      _isRefreshing = false;
      return true;
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'ApiClient', error: e);
      _isRefreshing = false;
      return false;
    }
  }

  /// Retry a failed request with new token
  Future<void> _retry(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      // Get new token
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        requestOptions.headers['Authorization'] = 'Bearer $token';
      }

      // Retry the request
      final response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } catch (e) {
      developer.log('Retry failed: $e', name: 'ApiClient', error: e);
      handler.next(e as DioException);
    }
  }

  /// Clear all session data
  Future<void> _clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'company_id');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'full_name');
    await _storage.delete(key: 'token_expiry');
    await _storage.delete(key: 'last_login');
  }

  Dio get dio => _dio;
}
