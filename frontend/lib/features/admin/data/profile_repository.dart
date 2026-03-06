import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/admin_models.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserDetail> getProfile() async {
    final response = await _apiClient.dio.get(ApiEndpoints.profile);
    return UserDetail.fromJson(response.data);
  }

  Future<UserDetail> updateProfile(UpdateProfileRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.profile,
      data: request.toJson(),
    );
    return UserDetail.fromJson(response.data);
  }

  Future<UserDetail> updateProfileImage(ProfileImageRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.profileImage,
      data: request.toJson(),
    );
    return UserDetail.fromJson(response.data);
  }

  Future<void> removeProfileImage() async {
    await _apiClient.dio.delete(ApiEndpoints.profileImage);
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    await _apiClient.dio.put(
      ApiEndpoints.profilePassword,
      data: request.toJson(),
    );
  }
}
