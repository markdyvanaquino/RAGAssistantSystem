
import 'package:intl/intl.dart';

class TimeUtil {

  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDay == today) {
      return "Today at ${DateFormat.jm().format(timestamp)}"; // Example: "Today at 2:30 PM"
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return "Yesterday at ${DateFormat.jm().format(timestamp)}"; // Example: "Yesterday at 5:45 AM"
    } else if (now.difference(timestamp).inDays < 7) {
      return "${DateFormat.EEEE().format(timestamp)} at ${DateFormat.jm().format(timestamp)}"; // Example: "Monday at 4:20 PM"
    } else {
      return "${DateFormat('MMM d, yyyy').format(timestamp)} at ${DateFormat.jm().format(timestamp)}"; // Example: "Jan 3, 2024 at 8:10 AM"
    }
  }
  static String formatCreationDate(DateTime timestamp) {
    return DateFormat("MMMM d, yyyy").format(timestamp);
  }
}
