import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';

  // Token
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  // User info
  Future<void> saveUserInfo({
    required String userId,
    required String role,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<String?> getRole() => _storage.read(key: _roleKey);
  Future<String?> getName() => _storage.read(key: _nameKey);
  Future<String?> getEmail() => _storage.read(key: _emailKey);

  Future<void> clearAll() => _storage.deleteAll();
}
