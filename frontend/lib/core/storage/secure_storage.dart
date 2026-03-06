import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _facilityIdKey = 'facility_id';
  static const _facilityNameKey = 'facility_name';

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
    String? facilityId,
    String facilityName = '',
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _emailKey, value: email);
    if (facilityId != null) {
      await _storage.write(key: _facilityIdKey, value: facilityId);
    }
    await _storage.write(key: _facilityNameKey, value: facilityName);
  }

  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<String?> getRole() => _storage.read(key: _roleKey);
  Future<String?> getName() => _storage.read(key: _nameKey);
  Future<String?> getEmail() => _storage.read(key: _emailKey);
  Future<String?> getFacilityId() => _storage.read(key: _facilityIdKey);
  Future<String?> getFacilityName() => _storage.read(key: _facilityNameKey);

  Future<void> clearAll() => _storage.deleteAll();
}
