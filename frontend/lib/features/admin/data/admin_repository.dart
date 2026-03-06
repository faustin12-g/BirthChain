import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/admin_models.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  // ══════════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════════

  Future<DashboardStats> getDashboardStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminDashboard);
    return DashboardStats.fromJson(response.data);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FACILITY MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════════

  Future<List<FacilityDetail>> getAllFacilities() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminFacilities);
    return (response.data as List)
        .map((json) => FacilityDetail.fromJson(json))
        .toList();
  }

  Future<FacilityDetail> getFacilityById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminFacilityById(id));
    return FacilityDetail.fromJson(response.data);
  }

  Future<FacilityDetail> updateFacility(String id, UpdateFacilityRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.adminFacilityById(id),
      data: request.toJson(),
    );
    return FacilityDetail.fromJson(response.data);
  }

  Future<void> activateFacility(String id) async {
    await _apiClient.dio.put(ApiEndpoints.adminActivateFacility(id));
  }

  Future<void> deactivateFacility(String id) async {
    await _apiClient.dio.put(ApiEndpoints.adminDeactivateFacility(id));
  }

  Future<void> deleteFacility(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.adminFacilityById(id));
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════════

  Future<List<UserDetail>> getAllUsers() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminUsers);
    return (response.data as List)
        .map((json) => UserDetail.fromJson(json))
        .toList();
  }

  Future<List<UserDetail>> getUsersByRole(String role) async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminUsersByRole(role));
    return (response.data as List)
        .map((json) => UserDetail.fromJson(json))
        .toList();
  }

  Future<UserDetail> getUserById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminUserById(id));
    return UserDetail.fromJson(response.data);
  }

  Future<UserDetail> updateUser(String id, UpdateUserRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.adminUserById(id),
      data: request.toJson(),
    );
    return UserDetail.fromJson(response.data);
  }

  Future<void> activateUser(String id) async {
    await _apiClient.dio.put(ApiEndpoints.adminActivateUser(id));
  }

  Future<void> deactivateUser(String id) async {
    await _apiClient.dio.put(ApiEndpoints.adminDeactivateUser(id));
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.adminUserById(id));
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // PROVIDER MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════════

  Future<List<ProviderDetail>> getAllProviders() async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminProviders);
    return (response.data as List)
        .map((json) => ProviderDetail.fromJson(json))
        .toList();
  }

  Future<List<ProviderDetail>> getProvidersByFacility(String facilityId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminProvidersByFacility(facilityId));
    return (response.data as List)
        .map((json) => ProviderDetail.fromJson(json))
        .toList();
  }

  Future<ProviderDetail> getProviderById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.adminProviderById(id));
    return ProviderDetail.fromJson(response.data);
  }

  Future<ProviderDetail> updateProvider(String id, UpdateProviderRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.adminProviderById(id),
      data: request.toJson(),
    );
    return ProviderDetail.fromJson(response.data);
  }

  Future<void> activateProvider(String id) async {
    await _apiClient.dio.put(ApiEndpoints.adminActivateProvider(id));
  }

  Future<void> deactivateProvider(String id) async {
    await _apiClient.dio.put(ApiEndpoints.adminDeactivateProvider(id));
  }

  Future<void> deleteProvider(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.adminProviderById(id));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FACILITY ADMIN REPOSITORY (for FacilityAdmin role)
// ══════════════════════════════════════════════════════════════════════════════

class FacilityAdminRepository {
  final ApiClient _apiClient;

  FacilityAdminRepository(this._apiClient);

  Future<FacilityDetail> getMyFacility() async {
    final response = await _apiClient.dio.get(ApiEndpoints.facilityAdminMyFacility);
    return FacilityDetail.fromJson(response.data);
  }

  Future<List<ProviderDetail>> getMyProviders() async {
    final response = await _apiClient.dio.get(ApiEndpoints.facilityAdminProviders);
    return (response.data as List)
        .map((json) => ProviderDetail.fromJson(json))
        .toList();
  }

  Future<ProviderDetail> getProviderById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.facilityAdminProviderById(id));
    return ProviderDetail.fromJson(response.data);
  }

  Future<ProviderDetail> updateProvider(String id, UpdateProviderRequest request) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.facilityAdminProviderById(id),
      data: request.toJson(),
    );
    return ProviderDetail.fromJson(response.data);
  }

  Future<void> activateProvider(String id) async {
    await _apiClient.dio.put(ApiEndpoints.facilityAdminActivateProvider(id));
  }

  Future<void> deactivateProvider(String id) async {
    await _apiClient.dio.put(ApiEndpoints.facilityAdminDeactivateProvider(id));
  }

  Future<void> deleteProvider(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.facilityAdminProviderById(id));
  }
}
