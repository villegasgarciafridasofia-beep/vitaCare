import 'package:flutter/foundation.dart';

import '../../models/alarm_payload.dart';
import 'alarm_scheduler.dart';

class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  Future<void> scheduleAlarm({required AlarmPayload payload}) async {
    debugPrint(
      'AlarmService: preparando alarma de '
      '${payload.medicationName}',
    );

    await AlarmScheduler.instance.schedule(payload: payload);
  }

  Future<void> cancelAlarm(int notificationId) async {
    await AlarmScheduler.instance.cancel(notificationId: notificationId);
  }

  Future<void> cancelAllAlarms() async {
    await AlarmScheduler.instance.cancelAll();
  }
}
