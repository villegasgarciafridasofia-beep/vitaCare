import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/alarm_payload.dart';
import '../../models/medication_log_model.dart';
import '../../views/medications/medication_alarm_view.dart';
import '../medication_log_service.dart';
import '../navigation_service.dart';

class AlarmReceiver {
  AlarmReceiver._();

  static final AlarmReceiver instance = AlarmReceiver._();

  final MedicationLogService _logService = MedicationLogService();

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

  Future<void> handlePayload(String? encodedPayload) async {
    if (_openingAlarm) {
      debugPrint('AlarmReceiver: ya se está abriendo una alarma.');
      return;
    }

    final AlarmPayload? payload = decodePayload(encodedPayload);

    if (payload == null) {
      return;
    }

    if (payload.medicationLogId.trim().isEmpty) {
      debugPrint('AlarmReceiver: medicationLogId está vacío.');
      return;
    }

    _openingAlarm = true;

    try {
      await NavigationService.waitUntilAppReady();

      debugPrint('Buscando registro: ${payload.medicationLogId}');

      final MedicationLogModel? medicationLog = await _logService.getLogById(
        logId: payload.medicationLogId,
      );

      // Continúa el código...

      if (medicationLog == null) {
        debugPrint(
          'AlarmReceiver: no se encontró el registro '
          'de la dosis en Firestore.',
        );
        return;
      }

      /*
       * Cuando la aplicación estaba completamente cerrada,
       * el Navigator puede tardar unos instantes en estar listo.
       */
      final NavigatorState? navigator = await _waitForNavigator();

      if (navigator == null) {
        debugPrint('AlarmReceiver: el navegador todavía no está disponible.');
        return;
      }

      debugPrint('Abriendo MedicationAlarmView.');
      debugPrint("1. Antes del push");
      await navigator.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) {
            debugPrint("2. Entró al builder");

            return MedicationAlarmView(medicationLog: medicationLog);
          },
        ),
      );

      debugPrint("3. Regresó del push");
      await navigator.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) {
            return MedicationAlarmView(medicationLog: medicationLog);
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('AlarmReceiver: error abriendo la alarma: $error');

      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _openingAlarm = false;
    }
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
