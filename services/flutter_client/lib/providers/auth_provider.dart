import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.status,
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._authService, this._tokenStorage)
      : super(AuthState(status: AuthStatus.unknown)) {
    _init();
  }

  Future<void> _init() async {
    final token = await _tokenStorage.loadToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final meResponse = await _authService.getCurrentUser(token);
      final userData = meResponse['user'] as Map<String, dynamic>?;
      if (userData != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          user: User.fromJson(userData),
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        await _tokenStorage.clearToken();
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      await _tokenStorage.clearToken();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(
        username: username,
        password: password,
      );
      await _tokenStorage.saveToken(
        response.accessToken,
        expiresInSeconds: response.expiresIn,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: response.accessToken,
        user: response.user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AuthError ? e.message : 'An error occurred',
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      await _tokenStorage.saveToken(
        response.accessToken,
        expiresInSeconds: response.expiresIn,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: response.accessToken,
        user: response.user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AuthError ? e.message : 'An error occurred',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(authService, tokenStorage);
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
