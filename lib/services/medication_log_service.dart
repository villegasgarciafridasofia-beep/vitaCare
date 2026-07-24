import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication_log_model.dart';

class MedicationLogService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
  get _logsCollection {
    return _db.collection(
      'medication_logs',
    );
  }

  Future<void> createPendingLog({
    required MedicationLogModel log,
  }) async {
    await _logsCollection.doc(log.id).set(
      log.toMap(),
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<MedicationLogModel?> getLogById({
    required String logId,
  }) async {
    if (logId.trim().isEmpty) {
      return null;
    }

    final document =
    await _logsCollection.doc(logId).get();

    if (!document.exists ||
        document.data() == null) {
      return null;
    }

    return MedicationLogModel.fromMap(
      document.data()!,
    );
  }

  Future<void> markAsTaken({
    required String logId,
  }) async {
    _validateLogId(logId);

    final now = DateTime.now();

    await _logsCollection.doc(logId).set(
      {
        'status': 'taken',
        'confirmedAt': Timestamp.fromDate(now),
        'takenAt': Timestamp.fromDate(now),
        'skipReason': null,
        'skippedAt': null,
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> markAsSnoozed({
    required String logId,
  }) async {
    _validateLogId(logId);

    final document =
    await _logsCollection.doc(logId).get();

    if (!document.exists ||
        document.data() == null) {
      throw Exception(
        'No se encontró el registro de la dosis.',
      );
    }

    final currentLog =
    MedicationLogModel.fromMap(
      document.data()!,
    );

    final now = DateTime.now();

    await _logsCollection.doc(logId).set(
      {
        'status': 'snoozed',
        'snoozeCount':
        currentLog.snoozeCount + 1,
        'snoozedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> markAsPendingAgain({
    required String logId,
    required DateTime newScheduledDateTime,
    required String newScheduledTime,
  }) async {
    _validateLogId(logId);

    final now = DateTime.now();

    await _logsCollection.doc(logId).set(
      {
        'status': 'pending',
        'scheduledDateTime':
        Timestamp.fromDate(
          newScheduledDateTime,
        ),
        'scheduledTime': newScheduledTime,
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> markAsSkipped({
    required String logId,
    required String reason,
  }) async {
    _validateLogId(logId);

    final sanitizedReason = reason.trim();

    if (sanitizedReason.isEmpty) {
      throw ArgumentError(
        'Debes indicar el motivo de la omisión.',
      );
    }

    final document =
    await _logsCollection.doc(logId).get();

    if (!document.exists) {
      throw Exception(
        'No se encontró el registro de la dosis.',
      );
    }

    final now = DateTime.now();

    await _logsCollection.doc(logId).set(
      {
        'status': 'skipped',
        'skipReason': sanitizedReason,
        'skippedAt': Timestamp.fromDate(now),
        'confirmedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> markAsMissed({
    required String logId,
  }) async {
    _validateLogId(logId);

    final now = DateTime.now();

    await _logsCollection.doc(logId).set(
      {
        'status': 'missed',
        'missedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> markAsCancelled({
    required String logId,
  }) async {
    _validateLogId(logId);

    final now = DateTime.now();

    await _logsCollection.doc(logId).set(
      {
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<List<MedicationLogModel>>
  getPatientLogs(
      String patientUid,
      ) async {
    if (patientUid.trim().isEmpty) {
      return [];
    }

    final query = await _logsCollection
        .where(
      'patientUid',
      isEqualTo: patientUid,
    )
        .get();

    final logs = query.docs
        .map(
          (document) =>
          MedicationLogModel.fromMap(
            document.data(),
          ),
    )
        .toList();

    logs.sort(
          (a, b) => b.scheduledDateTime
          .compareTo(
        a.scheduledDateTime,
      ),
    );

    return logs;
  }

  Future<List<MedicationLogModel>>
  getMedicationLogs({
    required String patientUid,
    required String medicationId,
  }) async {
    if (patientUid.trim().isEmpty ||
        medicationId.trim().isEmpty) {
      return [];
    }

    final query = await _logsCollection
        .where(
      'patientUid',
      isEqualTo: patientUid,
    )
        .where(
      'medicationId',
      isEqualTo: medicationId,
    )
        .get();

    final logs = query.docs
        .map(
          (document) =>
          MedicationLogModel.fromMap(
            document.data(),
          ),
    )
        .toList();

    logs.sort(
          (a, b) => b.scheduledDateTime
          .compareTo(
        a.scheduledDateTime,
      ),
    );

    return logs;
  }

  void _validateLogId(
      String logId,
      ) {
    if (logId.trim().isEmpty) {
      throw ArgumentError(
        'El identificador del registro está vacío.',
      );
    }
  }
}