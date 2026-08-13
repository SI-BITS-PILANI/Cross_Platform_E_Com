import '../models/user.dart';

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthError implements Exception {
  final String code;
  final String message;

  AuthError({required this.code, required this.message});

  factory AuthError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>;
    return AuthError(
      code: error['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error['message'] as String? ?? 'An error occurred',
    );
  }

  @override
  String toString() => 'AuthError($code: $message)';
}
