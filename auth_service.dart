import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static const String baseUrl = 'https://your-api.com/api';

  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/signup');

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );
    } catch (_) {
      throw AuthException('Cannot connect to server. Please try again.');
    }

    final data = _safeDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _persistAuthData(data);
      return;
    }

    throw AuthException(
      data['message']?.toString() ??
          data['error']?.toString() ??
          'Signup failed. Please try again.',
    );
  }

  /// NEW: Login user and persist auth data
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );
    } catch (_) {
      throw AuthException('Cannot connect to server. Please try again.');
    }

    final data = _safeDecode(response.body);

    if (response.statusCode == 200) {
      await _persistAuthData(data);
      return;
    }

    throw AuthException(
      data['message']?.toString() ??
          data['error']?.toString() ??
          'Login failed. Please check your credentials.',
    );
  }

static Future<void> _persistAuthData(Map<String, dynamic> data) async {
  final token = data['token']?.toString();

  String? userId;
  String? userName;
  String? userEmail;

  final user = data['user'];
  if (user is Map<String, dynamic>) {
    userId = user['id']?.toString();
    userName = user['name']?.toString();
    userEmail = user['email']?.toString();
  }

  await LocalStorageService.instance.saveAuthSession(
    token: token,
    userId: userId,
    userName: userName,
    userEmail: userEmail,
  );
}

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

 static Future<void> logout() async {
  await LocalStorageService.instance.clearAuthSession();
}

static Future<String?> getSavedToken() async {
  return LocalStorageService.instance.getAuthToken();
}
}
