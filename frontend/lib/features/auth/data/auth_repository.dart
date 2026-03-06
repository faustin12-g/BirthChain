import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    // Persist session
    await _storage.saveToken(loginResponse.token);
    await _storage.saveUserInfo(
      userId: loginResponse.userId,
      role: loginResponse.role,
      name: loginResponse.fullName,
      email: loginResponse.email,
      facilityId: loginResponse.facilityId,
      facilityName: loginResponse.facilityName,
    );

    return loginResponse;
  }

  Future<LoginResponse> register(RegisterRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    // Persist session — patient is logged in immediately
    await _storage.saveToken(loginResponse.token);
    await _storage.saveUserInfo(
      userId: loginResponse.userId,
      role: loginResponse.role,
      name: loginResponse.fullName,
      email: loginResponse.email,
      facilityId: loginResponse.facilityId,
      facilityName: loginResponse.facilityName,
    );

    return loginResponse;
  }

  Future<void> sendOtp(String email) async {
    await _apiClient.dio.post(ApiEndpoints.sendOtp, data: {'email': email});
  }

  Future<void> verifyEmail(String email, String code) async {
    await _apiClient.dio.post(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await _apiClient.dio.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getRole() => _storage.getRole();
  Future<String?> getName() => _storage.getName();
  Future<String?> getUserId() => _storage.getUserId();
  Future<String?> getFacilityId() => _storage.getFacilityId();
  Future<String?> getFacilityName() => _storage.getFacilityName();
}
