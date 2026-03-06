import 'package:flutter/material.dart';

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

/// Manages in-app notifications. Notifications are generated client-side
/// based on user activity — new records, welcome messages, etc.
class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications..sort((a, b) => b.timestamp.compareTo(a.timestamp)));

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  void addNotification(AppNotification notification) {
    // Avoid duplicates by id
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.add(notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n != null && !n.isRead) {
      n.isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    var changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Generate smart notifications based on records data.
  void generateFromRecords(List<dynamic> records, String? patientName) {
    if (records.isEmpty && patientName != null) {
      addNotification(AppNotification(
        id: 'welcome',
        title: 'Welcome to BirthChain!',
        subtitle: 'Your account is set up. Visit a provider to start tracking your health.',
        icon: Icons.celebration,
        color: Colors.blue,
        timestamp: DateTime.now(),
      ));
    }

    if (records.isNotEmpty) {
      // Notify about latest record
      final latest = records.last;
      final recId = latest is Map ? (latest['id'] ?? '') : '';
      addNotification(AppNotification(
        id: 'record-$recId',
        title: 'New Record Added',
        subtitle: 'A healthcare provider added a new record to your file.',
        icon: Icons.note_add,
        color: Colors.green,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ));
    }

    if (records.length >= 5) {
      addNotification(AppNotification(
        id: 'milestone-5',
        title: 'Health Milestone!',
        subtitle: 'You now have ${records.length} records in your health history.',
        icon: Icons.emoji_events,
        color: Colors.amber,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ));
    }
  }
}
