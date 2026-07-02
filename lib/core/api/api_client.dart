import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config.dart';

/// A function that returns the current Clerk session JWT, or null if the
/// user isn't signed in. Wired up in main.dart once Clerk is initialized.
typedef TokenProvider = Future<String?> Function();

/// Thin wrapper around Dio configured to talk to the EnvyEnhance API.
///
/// Handles:
/// - Base URL + JSON headers
/// - Attaching `Authorization: Bearer <clerk-jwt>` on every request when
///   the user is signed in
/// - Render free-tier cold starts (long timeout + one retry)
/// - Centralized error surface via [ApiException]
class ApiClient {
  ApiClient({TokenProvider? tokenProvider})
      : _tokenProvider = tokenProvider {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api',
        // Render free tier can take 30-60s to wake from cold start.
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_tokenProvider != null) {
            final token = await _tokenProvider();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          _logger.e(
            'API error: ${error.requestOptions.method} ${error.requestOptions.path}',
            error: error.response?.data ?? error.message,
          );
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenProvider? _tokenProvider;
  final Logger _logger = Logger();

  /// Allows updating the token provider after construction (e.g. once
  /// Clerk finishes initializing, which happens after ApiClient is first
  /// created via Riverpod).
  TokenProvider? _override;
  set tokenProvider(TokenProvider provider) => _override = provider;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: query);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: query);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
  }) async {
    try {
      return await _dio.put<T>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Normalized error type so UI code never has to deal with Dio directly.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'The server is waking up, please try again in a moment.';
    } else if (data is Map && data['error'] != null) {
      message = data['error'].toString();
    } else if (e.response?.statusCode == 401) {
      message = 'Please sign in to continue.';
    } else if (e.response?.statusCode == 403) {
      message = 'You don\'t have permission to do that.';
    } else if (e.response?.statusCode == 404) {
      message = 'Not found.';
    }

    return ApiException(message, statusCode: e.response?.statusCode);
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
