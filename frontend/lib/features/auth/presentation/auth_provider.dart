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
  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get role => _role;
  String? get name => _name;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _role == 'Admin';
  bool get isPatient => _role == 'Patient';

  Future<void> checkSession() async {
    _isLoggedIn = await _repo.isLoggedIn();
    if (_isLoggedIn) {
      _role = await _repo.getRole();
      _name = await _repo.getName();
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
    notifyListeners();
  }
}
