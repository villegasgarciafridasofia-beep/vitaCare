import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/alarm_payload.dart';

class AlarmReceiver {
  AlarmReceiver._();

  static final AlarmReceiver instance = AlarmReceiver._();

  AlarmPayload? decodePayload(String? encodedPayload) {
    if (encodedPayload == null || encodedPayload.trim().isEmpty) {
      debugPrint(
        'AlarmReceiver: la notificación no contiene payload.',
      );

      return null;
    }

    try {
      final dynamic decodedJson = jsonDecode(encodedPayload);

      if (decodedJson is! Map<String, dynamic>) {
        debugPrint(
          'AlarmReceiver: el payload no tiene un formato válido.',
        );

        return null;
      }

      final AlarmPayload alarmPayload =
      AlarmPayload.fromMap(decodedJson);

      debugPrint(
        'AlarmReceiver: alarma recibida para '
            '${alarmPayload.medicationName}.',
      );

      return alarmPayload;
    } catch (error, stackTrace) {
      debugPrint(
        'AlarmReceiver: error al leer el payload: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<void> handlePayload(String? encodedPayload) async {
    final AlarmPayload? payload =
    decodePayload(encodedPayload);

    if (payload == null) {
      return;
    }

    debugPrint(
      'Medicamento: ${payload.medicationName}',
    );

    debugPrint(
      'Dosis: ${payload.dose}',
    );

    debugPrint(
      'Hora programada: ${payload.scheduledTime}',
    );

    /*
     * Más adelante, desde aquí abriremos MedicationAlarmView.
     */
  }
}