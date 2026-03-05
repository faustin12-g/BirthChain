import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/patient_repository.dart';
import '../domain/patient_models.dart';

class PatientProvider extends ChangeNotifier {
  final PatientRepository _repo;

  PatientProvider(this._repo);

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _isLoading = false;
  String? _error;

  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _repo.getAll();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load patients.';
    } catch (_) {
      _error = 'Something went wrong.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Patient?> create(CreatePatientRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final patient = await _repo.create(request);
      _patients.insert(0, patient);
      _isLoading = false;
      notifyListeners();
      return patient;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to register patient.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Patient?> lookupByQr(String qrCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final patient = await _repo.getByQrCode(qrCode);
      _selectedPatient = patient;
      _isLoading = false;
      notifyListeners();
      return patient;
    } catch (_) {
      _error = 'Patient not found.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearSelection() {
    _selectedPatient = null;
    notifyListeners();
  }
}
