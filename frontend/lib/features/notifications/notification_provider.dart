import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_endpoints.dart';

/// A simple in-app notification model representing events to show in the bell.
class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.isRead = false,
  });
}

/// Manages in-app notifications. Fetches from backend API and also supports
/// client-side generated notifications.
class NotificationProvider extends ChangeNotifier {
  final Dio _dio;
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;

  NotificationProvider(this._dio);

  List<AppNotification> get notifications => List.unmodifiable(
    _notifications..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
  );

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  bool get isLoading => _isLoading;

  /// Load notifications from backend API
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      final List<dynamic> data = response.data ?? [];

      for (final item in data) {
        final notification = AppNotification(
          id: item['id']?.toString() ?? '',
          title: item['title'] ?? 'Notification',
          subtitle: item['body'] ?? '',
          icon: _getIconForTitle(item['title'] ?? ''),
          color: _getColorForTitle(item['title'] ?? ''),
          timestamp:
              DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
          isRead: item['isRead'] ?? false,
        );

        // Avoid duplicates
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.add(notification);
        }
      }
    } catch (e) {
      debugPrint('Failed to load notifications from API: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('facility')) return Icons.local_hospital;
    if (lower.contains('record')) return Icons.note_add;
    if (lower.contains('birth')) return Icons.child_care;
    if (lower.contains('welcome')) return Icons.celebration;
    return Icons.notifications;
  }

  Color _getColorForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('facility')) return Colors.blue;
    if (lower.contains('record')) return Colors.green;
    if (lower.contains('birth')) return Colors.pink;
    if (lower.contains('welcome')) return Colors.purple;
    return Colors.teal;
  }

  void addNotification(AppNotification notification) {
    // Avoid duplicates by id
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.add(notification);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n != null && !n.isRead) {
      n.isRead = true;
      notifyListeners();

      // Also update on backend
      try {
        await _dio.put(ApiEndpoints.notificationMarkRead(id));
      } catch (e) {
        debugPrint('Failed to mark notification as read on server: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    var changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();

      // Also update on backend
      try {
        await _dio.put(ApiEndpoints.notificationMarkAllRead);
      } catch (e) {
        debugPrint('Failed to mark all as read on server: $e');
      }
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Generate smart notifications based on records data (client-side).
  void generateFromRecords(List<dynamic> records, String? patientName) {
    if (records.isEmpty && patientName != null) {
      addNotification(
        AppNotification(
          id: 'welcome',
          title: 'Welcome to Sanara!',
          subtitle:
              'Your account is set up. Visit a provider to start tracking your health.',
          icon: Icons.celebration,
          color: Colors.blue,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (records.isNotEmpty) {
      // Notify about latest record
      final latest = records.last;
      final recId = latest is Map ? (latest['id'] ?? '') : '';
      addNotification(
        AppNotification(
          id: 'record-$recId',
          title: 'New Record Added',
          subtitle: 'A healthcare provider added a new record to your file.',
          icon: Icons.note_add,
          color: Colors.green,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
    }

    if (records.length >= 5) {
      addNotification(
        AppNotification(
          id: 'milestone-5',
          title: 'Health Milestone!',
          subtitle:
              'You now have ${records.length} records in your health history.',
          icon: Icons.emoji_events,
          color: Colors.amber,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      );
    }
  }
}
