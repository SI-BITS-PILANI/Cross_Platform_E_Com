import '../models/auth_response.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    return await _apiClient.getJson('/auth/me', token: token);
  }
}
