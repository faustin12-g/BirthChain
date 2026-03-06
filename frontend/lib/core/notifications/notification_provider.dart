import 'package:flutter/material.dart';
import 'notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  int get badgeCount =>
      notifications.where((n) => !(n['isRead'] ?? false)).length;

  NotificationProvider(this.repository);

  Future<void> loadNotifications() async {
    isLoading = true;
    notifyListeners();
    try {
      notifications = await repository.fetchNotifications();
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n['id'].toString() == id);
    if (index != -1) {
      notifications[index]['isRead'] = true;
      notifyListeners();
      try {
        await repository.markAsRead(id);
      } catch (e) {
        debugPrint('Failed to mark notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
    try {
      await repository.markAllAsRead();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }
}
