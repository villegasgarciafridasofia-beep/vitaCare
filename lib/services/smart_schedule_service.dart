class SmartScheduleService {
  List<String> generateMedicationTimes({
    required String frequency,
    required String wakeUpTime,
    required String breakfastTime,
    required String lunchTime,
    required String dinnerTime,
    required String sleepTime,
    required bool allowNightReminders,
  }) {
    switch (frequency) {
      case 'Una vez al día':
      case 'Cada 24 horas':
        return [breakfastTime.isNotEmpty ? breakfastTime : wakeUpTime];

      case 'Cada 12 horas':
        return _generateIntervalTimes(
          startTime: wakeUpTime,
          intervalHours: 12,
          sleepTime: sleepTime,
          allowNightReminders: allowNightReminders,
        );

      case 'Cada 8 horas':
        return _generateIntervalTimes(
          startTime: wakeUpTime,
          intervalHours: 8,
          sleepTime: sleepTime,
          allowNightReminders: allowNightReminders,
        );

      case 'Cada 6 horas':
        return _generateIntervalTimes(
          startTime: wakeUpTime,
          intervalHours: 6,
          sleepTime: sleepTime,
          allowNightReminders: allowNightReminders,
        );

      case 'Antes de dormir':
        return [sleepTime];

      default:
        return [];
    }
  }

  List<String> _generateIntervalTimes({
    required String startTime,
    required int intervalHours,
    required String sleepTime,
    required bool allowNightReminders,
  }) {
    if (startTime.isEmpty) {
      return [];
    }

    final startMinutes = _timeToMinutes(startTime);
    final sleepMinutes = sleepTime.isEmpty
        ? 24 * 60
        : _timeToMinutes(sleepTime);

    final List<String> times = [];
    int currentMinutes = startMinutes;

    const minutesInDay = 24 * 60;

    while (times.length < 4) {
      final normalizedMinutes = currentMinutes % minutesInDay;

      final isNightTime =
          sleepTime.isNotEmpty && normalizedMinutes > sleepMinutes;

      if (allowNightReminders || !isNightTime) {
        times.add(_minutesToTime(normalizedMinutes));
      }

      currentMinutes += intervalHours * 60;

      if (!allowNightReminders &&
          currentMinutes % minutesInDay > sleepMinutes) {
        break;
      }
    }

    return times;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  String _minutesToTime(int minutes) {
    final normalizedMinutes = minutes % (24 * 60);

    final hour = normalizedMinutes ~/ 60;
    final minute = normalizedMinutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
