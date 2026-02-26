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
  // TODO: Replace with your real backend URL
  static const String baseUrl = 'https://your-api.com/api';

  /// Signup user and persist auth data if backend returns token.
  ///
  /// Expected success response example:
  /// {
  ///   "token": "jwt_token_here",
  ///   "user": {
  ///     "id": "123",
  ///     "name": "John Doe",
  ///     "email": "john@example.com"
  ///   }
  /// }
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
    } catch (e) {
      throw AuthException('Cannot connect to server. Please try again.');
    }

    final Map<String, dynamic> data = _safeDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // If backend auto-login on signup and returns token => save it
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

      return;
    }

    // Handle common API error formats
    final message =
        data['message']?.toString() ??
        data['error']?.toString() ??
        'Signup failed. Please try again.';
    throw AuthException(message);
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
