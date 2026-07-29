class ReminderUtils {
  static List<String> generateReminderTimes({
    required String wakeUpTime,
    required String sleepTime,
    required int intervalHours,
  }) {
    final wakeParts = wakeUpTime.split(':');
    final sleepParts = sleepTime.split(':');

    DateTime current = DateTime(
      2026,
      1,
      1,
      int.parse(wakeParts[0]),
      int.parse(wakeParts[1]),
    );

    final DateTime sleep = DateTime(
      2026,
      1,
      1,
      int.parse(sleepParts[0]),
      int.parse(sleepParts[1]),
    );

    final List<String> times = [];

    while (current.isBefore(sleep) || current.isAtSameMomentAs(sleep)) {
      final hour = current.hour.toString().padLeft(2, '0');
      final minute = current.minute.toString().padLeft(2, '0');

      times.add('$hour:$minute');

      current = current.add(Duration(hours: intervalHours));
    }

    return times;
  }
}
