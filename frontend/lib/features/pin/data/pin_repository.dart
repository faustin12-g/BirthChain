import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PinRepository {
  final Dio _dio;
  PinRepository(ApiClient apiClient) : _dio = apiClient.dio;

  /// Get PIN status (hasPin, isLocked)
  Future<PinStatus> getPinStatus() async {
    final response = await _dio.get(ApiEndpoints.pinStatus);
    return PinStatus.fromJson(response.data);
  }

  /// Set PIN for the first time (requires password)
  Future<void> setPin(String pin, String password) async {
    await _dio.post(
      ApiEndpoints.pinSet,
      data: {'pin': pin, 'currentPassword': password},
    );
  }

  /// Change existing PIN
  Future<void> changePin(String currentPin, String newPin) async {
    await _dio.put(
      ApiEndpoints.pinChange,
      data: {'currentPin': currentPin, 'newPin': newPin},
    );
  }

  /// Remove PIN
  Future<void> removePin(String currentPin) async {
    await _dio.delete(ApiEndpoints.pinRemove, data: {'pin': currentPin});
  }

  /// Verify PIN (for self-access)
  Future<bool> verifyPin(String pin) async {
    final response = await _dio.post(
      ApiEndpoints.pinVerify,
      data: {'pin': pin},
    );
    return response.data['valid'] == true;
  }

  /// Look up client by QR code (returns LIMITED info + hasPinSet)
  Future<ClientLookup> lookupClientByQr(String qrCode) async {
    final response = await _dio.get(ApiEndpoints.clientLookup(qrCode));
    return ClientLookup.fromJson(response.data);
  }

  /// Verify PIN and get full client data
  Future<Map<String, dynamic>> verifyClientPin(
    String qrCode,
    String pin,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.clientVerifyPin(qrCode),
      data: {'pin': pin},
    );
    return response.data;
  }
}

class PinStatus {
  final bool hasPinSet;
  final bool isLocked;
  final int? lockoutMinutesRemaining;

  PinStatus({
    required this.hasPinSet,
    required this.isLocked,
    this.lockoutMinutesRemaining,
  });

  factory PinStatus.fromJson(Map<String, dynamic> json) {
    return PinStatus(
      hasPinSet: json['hasPinSet'] ?? false,
      isLocked: json['isLocked'] ?? false,
      lockoutMinutesRemaining: json['lockoutMinutesRemaining'],
    );
  }
}

class ClientLookup {
  final String id;
  final String fullName;
  final String qrCodeId;
  final bool hasPinSet;
  final bool requiresPin;

  ClientLookup({
    required this.id,
    required this.fullName,
    required this.qrCodeId,
    required this.hasPinSet,
    required this.requiresPin,
  });

  factory ClientLookup.fromJson(Map<String, dynamic> json) {
    return ClientLookup(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      qrCodeId: json['qrCodeId'] ?? '',
      hasPinSet: json['hasPinSet'] ?? false,
      requiresPin: json['requiresPin'] ?? json['hasPinSet'] ?? false,
    );
  }
}
