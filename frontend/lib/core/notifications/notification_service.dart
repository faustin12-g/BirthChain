import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../di/injection.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize(BuildContext context) async {
    await _messaging.requestPermission();
    
    // Get and save the FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await saveTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      saveTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Show a dialog or snackbar for foreground notifications
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.title ?? 'Notification'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // TODO: Navigate to notification details
              },
            ),
          ),
        );
      }
    });
  }

  static Future<void> saveTokenToBackend(String token) async {
    try {
      final api = getIt<ApiClient>();
      await api.dio.post(ApiEndpoints.notificationToken, data: {'token': token});
    } catch (e) {
      // Token save failed - user may not be logged in yet
      debugPrint('Failed to save FCM token: $e');
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
