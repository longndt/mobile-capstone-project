import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'local_storage_service.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// TODO: change to your backend URL
  /// Example:
  /// - local Android emulator: http://10.0.2.2:8000/api
  /// - local iOS simulator: http://127.0.0.1:8000/api
  /// - deployed: https://api.yourdomain.com/api
  static const String baseUrl = 'https://your-api.com/api';

  static const Duration _timeout = Duration(seconds: 15);

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse('$normalizedBase$normalizedPath');

    if (query == null || query.isEmpty) return uri;

    final queryParams = <String, String>{};
    query.forEach((key, value) {
      if (value != null) queryParams[key] = value.toString();
    });

    return uri.replace(queryParameters: queryParams);
  }

  Map<String, String> _headers({bool auth = false, Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = LocalStorageService.instance.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.get(
        _buildUri(path, query),
        headers: _headers(auth: auth, extra: headers),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.post(
        _buildUri(path, query),
        headers: _headers(auth: auth, extra: headers),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.put(
        _buildUri(path, query),
        headers: _headers(auth: auth, extra: headers),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.patch(
        _buildUri(path, query),
        headers: _headers(auth: auth, extra: headers),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.delete(
        _buildUri(path, query),
        headers: _headers(auth: auth, extra: headers),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _request(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(message: 'Request timeout. Please try again.');
    } on SocketException {
      throw const ApiException(message: 'No internet connection.');
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected API error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.trim();

    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      message: _extractMessage(decoded, fallbackStatusCode: statusCode),
      statusCode: statusCode,
      data: decoded,
    );
  }

  String _extractMessage(dynamic decoded, {required int fallbackStatusCode}) {
    if (decoded is Map<String, dynamic>) {
      final keys = ['message', 'error', 'detail', 'errors'];
      for (final k in keys) {
        final v = decoded[k];
        if (v == null) continue;
        if (v is String && v.trim().isNotEmpty) return v;
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is Map && v.isNotEmpty) return v.values.first.toString();
      }
    }
    return 'Request failed ($fallbackStatusCode)';
  }
}
