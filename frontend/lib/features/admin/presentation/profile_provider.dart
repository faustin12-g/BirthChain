import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/profile_repository.dart';
import '../domain/admin_models.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repo;

  ProfileProvider(this._repo);

  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  UserDetail? _profile;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  UserDetail? get profile => _profile;

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repo.getProfile();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to load profile.';
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      _profile = await _repo.updateProfile(
        UpdateProfileRequest(fullName: fullName, phone: phone),
      );
      _isLoading = false;
      _successMessage = 'Profile updated successfully!';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileImage(String base64Image, String contentType) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      _profile = await _repo.updateProfileImage(
        ProfileImageRequest(base64Image: base64Image, contentType: contentType),
      );
      _isLoading = false;
      _successMessage = 'Profile image updated!';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to update profile image.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeProfileImage() async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.removeProfileImage();
      await loadProfile(); // Refresh profile
      _isLoading = false;
      _successMessage = 'Profile image removed.';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to remove profile image.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repo.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      _isLoading = false;
      _successMessage = 'Password changed successfully!';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = e.response?.data?['message'] ?? 'Failed to change password.';
      notifyListeners();
      return false;
    }
  }
}
