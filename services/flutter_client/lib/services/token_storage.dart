import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _tokenKey = 'access_token';
  static const String _expiryKey = 'token_expiry';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token, {int expiresInSeconds = 3600}) async {
    final expiry = DateTime.now().add(Duration(seconds: expiresInSeconds)).millisecondsSinceEpoch;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiryKey, value: expiry.toString());
  }

  Future<String?> loadToken() async {
    final expiryStr = await _storage.read(key: _expiryKey);
    if (expiryStr != null) {
      final expiry = int.tryParse(expiryStr);
      if (expiry != null && DateTime.now().millisecondsSinceEpoch > expiry) {
        await clearToken();
        return null;
      }
    }
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
  }
}
