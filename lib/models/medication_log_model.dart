import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationLogModel {
  final String id;
  final String patientUid;
  final String medicationId;
  final String medicationName;

  final String scheduledTime;
  final DateTime scheduledDateTime;

  final DateTime? confirmedAt;

  final String status;
  final int snoozeCount;

  final String dose;
  final String instructions;

  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationLogModel({
    required this.id,
    required this.patientUid,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.scheduledDateTime,
    required this.confirmedAt,
    required this.status,
    required this.snoozeCount,
    required this.dose,
    required this.instructions,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicationLogModel copyWith({
    String? id,
    String? patientUid,
    String? medicationId,
    String? medicationName,
    String? scheduledTime,
    DateTime? scheduledDateTime,
    DateTime? confirmedAt,
    String? status,
    int? snoozeCount,
    String? dose,
    String? instructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationLogModel(
      id: id ?? this.id,
      patientUid: patientUid ?? this.patientUid,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      dose: dose ?? this.dose,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientUid': patientUid,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'confirmedAt': confirmedAt == null
          ? null
          : Timestamp.fromDate(confirmedAt!),
      'status': status,
      'snoozeCount': snoozeCount,
      'dose': dose,
      'instructions': instructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MedicationLogModel.fromMap(Map<String, dynamic> map) {
    return MedicationLogModel(
      id: map['id'] ?? '',
      patientUid: map['patientUid'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      scheduledDateTime: _dateFromValue(map['scheduledDateTime']),
      confirmedAt: map['confirmedAt'] == null
          ? null
          : _dateFromValue(map['confirmedAt']),
      status: map['status'] ?? 'pending',
      snoozeCount: map['snoozeCount'] ?? 0,
      dose: map['dose'] ?? '',
      instructions: map['instructions'] ?? '',
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
