import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/patient_repository.dart';
import '../domain/patient_models.dart';

class PatientProvider extends ChangeNotifier {
  final PatientRepository _repo;

  PatientProvider(this._repo);

  List<Patient> _patients = [];
  List<Patient> _searchResults = [];
  Patient? _selectedPatient;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';

  List<Patient> get patients => _patients;
  List<Patient> get searchResults => _searchResults;
  Patient? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;

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

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repo.search(query.trim());
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Search failed.';
      _searchResults = [];
    } catch (_) {
      _error = 'Search failed.';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
