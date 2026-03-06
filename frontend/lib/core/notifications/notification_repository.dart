import 'package:dio/dio.dart';
import '../network/api_endpoints.dart';

class NotificationRepository {
  final Dio dio;
  NotificationRepository(this.dio);

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await dio.get(ApiEndpoints.notifications);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> saveDeviceToken(String token) async {
    await dio.post(ApiEndpoints.notificationToken, data: {'token': token});
  }

  Future<void> markAsRead(String id) async {
    await dio.put(ApiEndpoints.notificationMarkRead(id));
  }

  Future<void> markAllAsRead() async {
    await dio.put(ApiEndpoints.notificationMarkAllRead);
  }
}
