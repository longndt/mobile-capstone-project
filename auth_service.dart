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
    final token = data['token'];
    final user = data['user'];

    final prefs = await SharedPreferences.getInstance();

    if (token != null) {
      await prefs.setString('auth_token', token.toString());
    }

    if (user is Map<String, dynamic>) {
      if (user['id'] != null) {
        await prefs.setString('user_id', user['id'].toString());
      }
      if (user['name'] != null) {
        await prefs.setString('user_name', user['name'].toString());
      }
      if (user['email'] != null) {
        await prefs.setString('user_email', user['email'].toString());
      }
    }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
