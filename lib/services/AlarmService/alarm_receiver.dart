import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/alarm_payload.dart';
import '../../models/medication_log_model.dart';
import '../../views/medications/medication_alarm_view.dart';
import '../medication_log_service.dart';
import '../navigation_service.dart';
import '../notification_history_service.dart';
import 'alarm_scheduler.dart';

class AlarmReceiver {
  AlarmReceiver._();

  static final AlarmReceiver instance = AlarmReceiver._();

  final MedicationLogService _logService = MedicationLogService();
  final NotificationHistoryService _historyService =
  NotificationHistoryService();

  bool _openingAlarm = false;

  AlarmPayload? decodePayload(String? encodedPayload) {
    if (encodedPayload == null || encodedPayload.trim().isEmpty) {
      debugPrint('AlarmReceiver: la notificación no contiene payload.');
      return null;
    }

    try {
      final dynamic decodedJson = jsonDecode(encodedPayload);

      if (decodedJson is! Map<String, dynamic>) {
        debugPrint('AlarmReceiver: el payload no tiene un formato válido.');
        return null;
      }

      final AlarmPayload alarmPayload = AlarmPayload.fromMap(decodedJson);

      debugPrint(
        'AlarmReceiver: alarma recibida para '
            '${alarmPayload.medicationName}.',
      );

      return alarmPayload;
    } catch (error, stackTrace) {
      debugPrint('AlarmReceiver: error al leer el payload: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<MedicationAlarmResult?> handlePayload(String? encodedPayload) async {
    if (_openingAlarm) {
      debugPrint('AlarmReceiver: ya se está abriendo una alarma.');
      return null;
    }

    final AlarmPayload? payload = decodePayload(encodedPayload);

    if (payload == null) {
      return null;
    }

    if (payload.medicationLogId.trim().isEmpty) {
      debugPrint('AlarmReceiver: medicationLogId está vacío.');
      return null;
    }

    _openingAlarm = true;

    try {
      await NavigationService.waitUntilAppReady();

      debugPrint('Buscando registro: ${payload.medicationLogId}');

      final MedicationLogModel? firestoreLog = await _logService.getLogById(
        logId: payload.medicationLogId,
      );

      final MedicationLogModel medicationLog = firestoreLog ??
          MedicationLogModel(
            id: payload.medicationLogId,
            patientUid: payload.patientUid,
            medicationId: payload.medicationId,
            medicationName: payload.medicationName,
            scheduledTime: payload.scheduledTime,
            scheduledDateTime: payload.scheduledDateTime,
            confirmedAt: null,
            status: 'pending',
            snoozeCount: 0,
            dose: payload.dose,
            instructions: payload.instructions,
            createdAt: payload.scheduledDateTime,
            updatedAt: DateTime.now(),
          );

      final NavigatorState? navigator = await _waitForNavigator();

      if (navigator == null) {
        debugPrint('AlarmReceiver: el navegador todavía no está disponible.');
        return null;
      }

      debugPrint('Abriendo MedicationAlarmView.');

      final MedicationAlarmResult? result = await navigator
          .push<MedicationAlarmResult>(
        MaterialPageRoute<MedicationAlarmResult>(
          fullscreenDialog: true,
          builder: (_) {
            return MedicationAlarmView(medicationLog: medicationLog);
          },
        ),
      );

      debugPrint('MedicationAlarmView terminó con: $result');

      if (result != null) {
        await _historyService.markAction(
          patientUid: payload.patientUid,
          notificationId: payload.notificationId,
          action: switch (result) {
            MedicationAlarmResult.taken => 'taken',
            MedicationAlarmResult.snoozed => 'snoozed',
            MedicationAlarmResult.skipped => 'skipped',
          },
        );
      }

      if (result == MedicationAlarmResult.snoozed) {
        await _scheduleSnooze(payload: payload);
      }

      return result;
    } catch (error, stackTrace) {
      debugPrint(
        'AlarmReceiver: error abriendo o '
            'reprogramando la alarma: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _openingAlarm = false;
    }
  }

  Future<void> _scheduleSnooze({required AlarmPayload payload}) async {
    final DateTime snoozeDateTime = DateTime.now().add(
      const Duration(minutes: 5),
    );

    final int newNotificationId = DateTime.now().millisecondsSinceEpoch
        .remainder(2147483647);

    final AlarmPayload snoozedPayload = AlarmPayload(
      notificationId: newNotificationId,
      medicationId: payload.medicationId,
      medicationLogId: payload.medicationLogId,
      patientUid: payload.patientUid,
      medicationName: payload.medicationName,
      dose: payload.dose,
      instructions: payload.instructions,
      scheduledTime: _formatTime(snoozeDateTime),
      scheduledDateTime: snoozeDateTime,
    );

    debugPrint(
      'PROGRAMANDO SNOOZE PARA: '
          '${snoozedPayload.scheduledDateTime}',
    );

    await AlarmScheduler.instance.schedule(payload: snoozedPayload);

    debugPrint('SNOOZE PROGRAMADO CON ID: $newNotificationId');
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<NavigatorState?> _waitForNavigator() async {
    for (int attempt = 0; attempt < 100; attempt++) {
      final NavigatorState? navigator = NavigationService.navigator;

      if (navigator != null) {
        return navigator;
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    return null;
  }
}
