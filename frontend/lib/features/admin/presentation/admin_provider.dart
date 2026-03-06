import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repo;

  AdminProvider(this._repo);

  bool _isLoading = false;
  String? _error;

  // Dashboard
  DashboardStats? _stats;

  // Facilities
  List<FacilityDetail> _facilities = [];
  FacilityDetail? _selectedFacility;

  // Users
  List<UserDetail> _users = [];
  UserDetail? _selectedUser;

  // Providers
  List<ProviderDetail> _providers = [];
  ProviderDetail? _selectedProvider;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardStats? get stats => _stats;
  List<FacilityDetail> get facilities => _facilities;
  FacilityDetail? get selectedFacility => _selectedFacility;
  List<UserDetail> get users => _users;
  UserDetail? get selectedUser => _selectedUser;
  List<ProviderDetail> get providers => _providers;
  ProviderDetail? get selectedProvider => _selectedProvider;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repo.getDashboardStats();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load dashboard.';
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FACILITY MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> loadFacilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _facilities = await _repo.getAllFacilities();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load facilities.';
      notifyListeners();
    }
  }

  Future<void> loadFacilityById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedFacility = await _repo.getFacilityById(id);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load facility.';
      notifyListeners();
    }
  }

  Future<bool> updateFacility(String id, UpdateFacilityRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedFacility = await _repo.updateFacility(id, request);
      await loadFacilities(); // Refresh list
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to update facility.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateFacility(String id) async {
    try {
      await _repo.activateFacility(id);
      await loadFacilities(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to activate facility.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateFacility(String id) async {
    try {
      await _repo.deactivateFacility(id);
      await loadFacilities(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to deactivate facility.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFacility(String id) async {
    try {
      await _repo.deleteFacility(id);
      await loadFacilities(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to delete facility.';
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> loadUsers({String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (role != null) {
        _users = await _repo.getUsersByRole(role);
      } else {
        _users = await _repo.getAllUsers();
      }
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load users.';
      notifyListeners();
    }
  }

  Future<void> loadUserById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUser = await _repo.getUserById(id);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load user.';
      notifyListeners();
    }
  }

  Future<bool> updateUser(String id, UpdateUserRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUser = await _repo.updateUser(id, request);
      await loadUsers(); // Refresh list
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to update user.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateUser(String id) async {
    try {
      await _repo.activateUser(id);
      await loadUsers(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to activate user.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateUser(String id) async {
    try {
      await _repo.deactivateUser(id);
      await loadUsers(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to deactivate user.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _repo.deleteUser(id);
      await loadUsers(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to delete user.';
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // PROVIDER MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> loadProviders({String? facilityId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (facilityId != null) {
        _providers = await _repo.getProvidersByFacility(facilityId);
      } else {
        _providers = await _repo.getAllProviders();
      }
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load providers.';
      notifyListeners();
    }
  }

  Future<void> loadProviderById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProvider = await _repo.getProviderById(id);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load provider.';
      notifyListeners();
    }
  }

  Future<bool> updateProvider(String id, UpdateProviderRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProvider = await _repo.updateProvider(id, request);
      await loadProviders(); // Refresh list
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to update provider.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateProvider(String id) async {
    try {
      await _repo.activateProvider(id);
      await loadProviders(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to activate provider.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateProvider(String id) async {
    try {
      await _repo.deactivateProvider(id);
      await loadProviders(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to deactivate provider.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProvider(String id) async {
    try {
      await _repo.deleteProvider(id);
      await loadProviders(); // Refresh list
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to delete provider.';
      notifyListeners();
      return false;
    }
  }
}
