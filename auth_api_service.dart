import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'local_storage_service.dart';

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
      auth: false,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid login response format');
    }

    await _persistAuthPayload(data);
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.signup,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
      auth: false,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid signup response format');
    }

    // If backend returns token + user on signup, we persist.
    // If not, user can be redirected to login.
    final hasToken = data['token'] != null;
    if (hasToken) {
      await _persistAuthPayload(data);
    }
  }

  Future<AppUser> getMe() async {
    final data = await ApiClient.instance.get(
      ApiEndpoints.me,
      auth: true,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid profile response format');
    }

    // Some backends return {user: {...}}, others return user directly
    final userMap = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : data;

    final user = AppUser(
      id: userMap['id']?.toString(),
      name: userMap['name']?.toString(),
      email: userMap['email']?.toString(),
    );

    await LocalStorageService.instance.saveAuthSession(
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
    );

    return user;
  }

  Future<void> logout() async {
    // Optional: if backend has logout endpoint, call it here
    // try { await ApiClient.instance.post('/auth/logout', auth: true); } catch (_) {}
    await LocalStorageService.instance.clearAuthSession();
  }

  Future<void> _persistAuthPayload(Map<String, dynamic> data) async {
    final token = data['token']?.toString() ?? data['accessToken']?.toString();

    final userMap = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    await LocalStorageService.instance.saveAuthSession(
      token: token,
      userId: userMap['id']?.toString(),
      userName: userMap['name']?.toString(),
      userEmail: userMap['email']?.toString(),
    );
  }
}
