import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo);

  bool _isLoading = false;
  String? _error;
  String? _role;
  String? _name;
  String? _facilityId;
  String? _facilityName;
  bool _isLoggedIn = false;
  String? _pendingVerificationEmail;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get role => _role;
  String? get name => _name;
  String? get facilityId => _facilityId;
  String? get facilityName => _facilityName;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _role == 'Admin';
  bool get isFacilityAdmin => _role == 'FacilityAdmin';
  bool get isPatient => _role == 'Patient';
  bool get isProvider => _role == 'Provider';
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  Future<void> checkSession() async {
    _isLoggedIn = await _repo.isLoggedIn();
    if (_isLoggedIn) {
      _role = await _repo.getRole();
      _name = await _repo.getName();
      _facilityId = await _repo.getFacilityId();
      _facilityName = await _repo.getFacilityName();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repo.login(
        LoginRequest(email: email, password: password),
      );
      _role = response.role;
      _name = response.fullName;
      _facilityId = response.facilityId;
      _facilityName = response.facilityName;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.statusCode == 401) {
        _error = 'Invalid email or password.';
      } else {
        _error =
            e.response?.data?['message'] ??
            'Connection error. Is the server running?';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repo.register(request);
      _role = response.role;
      _name = response.fullName;
      _pendingVerificationEmail = request.email;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.statusCode == 409) {
        _error =
            e.response?.data?['message'] ??
            'An account with this email already exists.';
      } else {
        _error =
            e.response?.data?['message'] ??
            'Connection error. Is the server running?';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _isLoggedIn = false;
    _role = null;
    _name = null;
    _facilityId = null;
    _facilityName = null;
    _pendingVerificationEmail = null;
    notifyListeners();
  }

  // ── OTP Methods ──

  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.sendOtp(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to send code.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.verifyEmail(email, code);
      _isLoading = false;
      _pendingVerificationEmail = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Invalid or expired code.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to send reset code.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.resetPassword(email, code, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to reset password.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong.';
      notifyListeners();
      return false;
    }
  }
}
