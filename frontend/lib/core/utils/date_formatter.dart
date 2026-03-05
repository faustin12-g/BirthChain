import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, y  h:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}
