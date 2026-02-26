import 'auth_api_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await AuthApiService.instance.signup(
        name: name,
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await AuthApiService.instance.login(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> logout() async {
    await AuthApiService.instance.logout();
  }

  static Future<String?> getSavedToken() async {
    return Future.value(null); // not needed if using LocalStorageService directly in main
  }
}
