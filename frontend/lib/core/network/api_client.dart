import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService _storage;

  ApiClient(this._storage) {
    String baseUrl;

    // Use production server if flag is set
    if (AppConstants.useProductionServer) {
      baseUrl = AppConstants.apiBaseUrlProduction;
    } else if (kIsWeb) {
      baseUrl = AppConstants.apiBaseUrlWindows;
    } else {
      try {
        baseUrl =
            Platform.isAndroid
                ? AppConstants.apiBaseUrl
                : AppConstants.apiBaseUrlWindows;
      } catch (_) {
        baseUrl = AppConstants.apiBaseUrlWindows;
      }
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _storage.clearAll();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
