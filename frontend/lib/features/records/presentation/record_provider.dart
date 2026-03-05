import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../patients/domain/patient_models.dart';
import '../data/record_repository.dart';
import '../domain/record_models.dart';

class RecordProvider extends ChangeNotifier {
  final RecordRepository _repo;

  RecordProvider(this._repo);

  List<MedicalRecord> _records = [];
  Patient? _currentClient;
  bool _isLoading = false;
  String? _error;

  List<MedicalRecord> get records => _records;
  Patient? get currentClient => _currentClient;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadByClientId(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getByClientId(clientId);
      _currentClient = result.client;
      _records = result.records;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load records.';
    } catch (_) {
      _error = 'Something went wrong.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadByQrCode(String qrCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getByQrCode(qrCode);
      _currentClient = result.client;
      _records = result.records;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Patient not found.';
      _records = [];
      _currentClient = null;
    } catch (_) {
      _error = 'Something went wrong.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<MedicalRecord?> create(CreateRecordRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final record = await _repo.create(request);
      _records.add(record);
      _isLoading = false;
      notifyListeners();
      return record;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to create record.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clear() {
    _records = [];
    _currentClient = null;
    _error = null;
    notifyListeners();
  }
}
