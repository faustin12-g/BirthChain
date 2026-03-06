import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/pin_repository.dart';

class PinProvider extends ChangeNotifier {
  final PinRepository _repository;

  PinStatus? _status;
  bool _isLoading = false;
  String? _error;
  bool _isPinVerified = false; // Session-level PIN verification

  // For provider client lookup
  ClientLookup? _clientLookup;
  Map<String, dynamic>? _verifiedClientData;

  PinProvider(this._repository);

  PinStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPinSet => _status?.hasPinSet ?? false;
  bool get isLocked => _status?.isLocked ?? false;
  bool get isPinVerified => _isPinVerified;
  ClientLookup? get clientLookup => _clientLookup;
  Map<String, dynamic>? get verifiedClientData => _verifiedClientData;

  Future<void> loadStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _status = await _repository.getPinStatus();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load PIN status';
    } catch (e) {
      _error = 'Something went wrong';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setPin(String pin, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.setPin(pin, password);
      await loadStatus();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to set PIN';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.changePin(currentPin, newPin);
      await loadStatus();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to change PIN';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removePin(String currentPin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.removePin(currentPin);
      _isPinVerified = false;
      await loadStatus();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to remove PIN';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final valid = await _repository.verifyPin(pin);
      if (valid) {
        _isPinVerified = true;
      }
      _isLoading = false;
      notifyListeners();
      return valid;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Invalid PIN';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset PIN verification (e.g., on logout or timeout)
  void resetPinVerification() {
    _isPinVerified = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Look up client by QR code (for providers) - returns limited info
  Future<ClientLookup?> lookupClientByQr(String qrCode) async {
    _isLoading = true;
    _error = null;
    _clientLookup = null;
    _verifiedClientData = null;
    notifyListeners();

    try {
      _clientLookup = await _repository.lookupClientByQr(qrCode);
      _isLoading = false;
      notifyListeners();
      return _clientLookup;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Patient not found';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Something went wrong';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Verify client's PIN and get full data (for providers)
  Future<Map<String, dynamic>?> verifyClientPinAndGetData(
    String qrCode,
    String pin,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _verifiedClientData = await _repository.verifyClientPin(qrCode, pin);
      _isLoading = false;
      notifyListeners();
      return _verifiedClientData;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Invalid PIN';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Something went wrong';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear client lookup data
  void clearClientLookup() {
    _clientLookup = null;
    _verifiedClientData = null;
    _error = null;
    notifyListeners();
  }
}
