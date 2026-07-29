import 'package:flutter/foundation.dart';

import '../../models/alarm_payload.dart';
import '../notification_service.dart';

class AlarmScheduler {
  AlarmScheduler._();

  static final AlarmScheduler instance = AlarmScheduler._();

  Future<void> schedule({required AlarmPayload payload}) async {
    final DateTime now = DateTime.now();

    if (!payload.scheduledDateTime.isAfter(now)) {
      throw ArgumentError(
        'La fecha de la alarma debe ser posterior a la fecha actual.',
      );
    }

    debugPrint(
      'Programando alarma: ${payload.medicationName} '
      'para ${payload.scheduledDateTime}',
    );

    await NotificationService.instance.scheduleMedicationNotification(
      payload: payload,
    );
  }

  Future<void> cancel({required int notificationId}) async {
    await NotificationService.instance.cancelNotification(notificationId);
  }

  Future<void> cancelAll() async {
    await NotificationService.instance.cancelAllNotifications();
  }
}
