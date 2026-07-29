import '../models/alarm_payload.dart';
import '../models/medication_log_model.dart';
import '../models/medication_model.dart';
import './AlarmService/alarm_service.dart';
import 'medication_log_service.dart';
import 'medication_service.dart';

class MedicationRegistrationService {
  MedicationRegistrationService({
    MedicationService? medicationService,
    MedicationLogService? medicationLogService,
    AlarmService? alarmService,
  }) : _medicationService = medicationService ?? MedicationService(),
       _medicationLogService = medicationLogService ?? MedicationLogService(),
       _alarmService = alarmService ?? AlarmService.instance;

  final MedicationService _medicationService;
  final MedicationLogService _medicationLogService;
  final AlarmService _alarmService;

  /// Guarda el medicamento y programa su siguiente dosis.
  ///
  /// Devuelve el registro creado para la alarma.
  /// Si el medicamento está inactivo, no tiene horarios o ya terminó
  /// el tratamiento, devuelve null.
  Future<MedicationLogModel?> registerMedication({
    required MedicationModel medication,
  }) async {
    // 1. Guardar el medicamento.
    await _medicationService.addMedication(medication);

    // 2. No programar alarmas para medicamentos inactivos.
    if (!medication.active) {
      return null;
    }

    // 3. Verificar que tenga horarios configurados.
    if (medication.times.isEmpty) {
      return null;
    }

    // 4. Calcular la siguiente dosis válida.
    final DateTime? nextScheduledDateTime = _findNextScheduledDateTime(
      medication: medication,
    );

    if (nextScheduledDateTime == null) {
      return null;
    }

    final String scheduledTime = _formatTime(nextScheduledDateTime);

    final String dose = '${medication.doseQuantity} ${medication.doseUnit}'
        .trim();

    /*
     * Se usa medicamento + fecha programada para evitar
     * registros duplicados de la misma dosis.
     */
    final String medicationLogId =
        '${medication.id}_${nextScheduledDateTime.millisecondsSinceEpoch}';

    final DateTime now = DateTime.now();

    // 5. Crear el registro pendiente.
    final MedicationLogModel medicationLog = MedicationLogModel(
      id: medicationLogId,
      patientUid: medication.patientUid,
      medicationId: medication.id,
      medicationName: medication.name,
      scheduledTime: scheduledTime,
      scheduledDateTime: nextScheduledDateTime,
      confirmedAt: null,
      status: 'pending',
      snoozeCount: 0,
      dose: dose,
      instructions: medication.instructions,
      createdAt: now,
      updatedAt: now,
    );

    await _medicationLogService.createPendingLog(log: medicationLog);

    // 6. Crear la información de la alarma.
    final AlarmPayload alarmPayload = AlarmPayload(
      notificationId: _generateNotificationId(medicationLogId),
      medicationId: medication.id,
      medicationLogId: medicationLog.id,
      patientUid: medication.patientUid,
      medicationName: medication.name,
      dose: dose,
      instructions: medication.instructions,
      scheduledTime: scheduledTime,
      scheduledDateTime: nextScheduledDateTime,
    );

    try {
      // 7. Programar la alarma.
      await _alarmService.scheduleAlarm(payload: alarmPayload);
    } catch (error) {
      /*
       * Si Android no permite programar la alarma,
       * dejamos constancia de que este registro fue cancelado.
       */
      await _medicationLogService.markAsCancelled(logId: medicationLog.id);

      rethrow;
    }

    return medicationLog;
  }

  DateTime? _findNextScheduledDateTime({required MedicationModel medication}) {
    final DateTime now = DateTime.now();

    final List<_MedicationTime> parsedTimes =
        medication.times.map(_parseTime).whereType<_MedicationTime>().toList()
          ..sort((a, b) {
            final int hourComparison = a.hour.compareTo(b.hour);

            if (hourComparison != 0) {
              return hourComparison;
            }

            return a.minute.compareTo(b.minute);
          });

    if (parsedTimes.isEmpty) {
      return null;
    }

    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime treatmentStartDate = DateTime(
      medication.startDate.year,
      medication.startDate.month,
      medication.startDate.day,
    );

    final DateTime firstDate = treatmentStartDate.isAfter(today)
        ? treatmentStartDate
        : today;

    /*
     * Como los horarios se repiten diariamente, basta revisar
     * la fecha inicial y el día siguiente.
     */
    for (int dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final DateTime currentDate = firstDate.add(Duration(days: dayOffset));

      if (_isAfterTreatmentEnd(
        currentDate: currentDate,
        endDate: medication.endDate,
      )) {
        return null;
      }

      for (final _MedicationTime time in parsedTimes) {
        final DateTime candidate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          time.hour,
          time.minute,
        );

        if (candidate.isBefore(medication.startDate)) {
          continue;
        }

        if (!candidate.isAfter(now)) {
          continue;
        }

        if (_isAfterTreatmentEnd(
          currentDate: candidate,
          endDate: medication.endDate,
        )) {
          return null;
        }

        return candidate;
      }
    }

    return null;
  }

  _MedicationTime? _parseTime(String value) {
    final List<String> parts = value.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23) {
      return null;
    }

    if (minute < 0 || minute > 59) {
      return null;
    }

    return _MedicationTime(hour: hour, minute: minute);
  }

  bool _isAfterTreatmentEnd({
    required DateTime currentDate,
    required DateTime? endDate,
  }) {
    if (endDate == null) {
      return false;
    }

    final DateTime currentDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final DateTime treatmentEndDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    return currentDay.isAfter(treatmentEndDay);
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');

    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  int _generateNotificationId(String value) {
    int hash = 17;

    for (final int character in value.codeUnits) {
      hash = ((hash * 31) + character) & 0x7fffffff;
    }

    return hash == 0 ? 1 : hash;
  }
}

class _MedicationTime {
  const _MedicationTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
