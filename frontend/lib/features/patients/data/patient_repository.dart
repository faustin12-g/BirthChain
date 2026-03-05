import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/patient_models.dart';

class PatientRepository {
  final ApiClient _apiClient;

  PatientRepository(this._apiClient);

  Future<Patient> create(CreatePatientRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.clients,
      data: request.toJson(),
    );
    return Patient.fromJson(response.data);
  }

  Future<List<Patient>> getAll() async {
    final response = await _apiClient.dio.get(ApiEndpoints.clients);
    final list = response.data as List;
    return list.map((e) => Patient.fromJson(e)).toList();
  }

  Future<Patient?> getByQrCode(String qrCode) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.clientByQr(qrCode),
      );
      return Patient.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Patient>> search(String query) async {
    final response = await _apiClient.dio.get(ApiEndpoints.clientSearch(query));
    final list = response.data as List;
    return list.map((e) => Patient.fromJson(e)).toList();
  }
}
