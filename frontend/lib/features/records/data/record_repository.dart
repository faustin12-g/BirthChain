import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../patients/domain/patient_models.dart';
import '../domain/record_models.dart';

class RecordRepository {
  final ApiClient _apiClient;

  RecordRepository(this._apiClient);

  Future<MedicalRecord> create(CreateRecordRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.records,
      data: request.toJson(),
    );
    return MedicalRecord.fromJson(response.data);
  }

  Future<({Patient client, List<MedicalRecord> records})> getByClientId(
    String clientId,
  ) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.recordsByClient(clientId),
    );
    final data = response.data;
    final client = Patient.fromJson(data['client']);
    final records =
        (data['records'] as List)
            .map((e) => MedicalRecord.fromJson(e))
            .toList();
    return (client: client, records: records);
  }

  Future<({Patient client, List<MedicalRecord> records})> getByQrCode(
    String qrCode,
  ) async {
    final response = await _apiClient.dio.get(ApiEndpoints.recordsByQr(qrCode));
    final data = response.data;
    final client = Patient.fromJson(data['client']);
    final records =
        (data['records'] as List)
            .map((e) => MedicalRecord.fromJson(e))
            .toList();
    return (client: client, records: records);
  }

  /// Patient: fetch own profile + records via GET /records/my
  Future<({Patient client, List<MedicalRecord> records})> getMyRecords() async {
    final response = await _apiClient.dio.get(ApiEndpoints.myRecords);
    final data = response.data;
    final client = Patient.fromJson(data['client']);
    final records =
        (data['records'] as List)
            .map((e) => MedicalRecord.fromJson(e))
            .toList();
    return (client: client, records: records);
  }
}
