class AlarmPayload {
  final int notificationId;
  final String medicationId;
  final String medicationLogId;
  final String patientUid;
  final String medicationName;
  final String dose;
  final String instructions;
  final String scheduledTime;
  final DateTime scheduledDateTime;

  const AlarmPayload({
    required this.notificationId,
    required this.medicationId,
    required this.medicationLogId,
    required this.patientUid,
    required this.medicationName,
    required this.dose,
    required this.instructions,
    required this.scheduledTime,
    required this.scheduledDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'medicationId': medicationId,
      'medicationLogId': medicationLogId,
      'patientUid': patientUid,
      'medicationName': medicationName,
      'dose': dose,
      'instructions': instructions,
      'scheduledTime': scheduledTime,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
    };
  }

  factory AlarmPayload.fromMap(Map<String, dynamic> map) {
    return AlarmPayload(
      notificationId: map['notificationId'] as int,
      medicationId: map['medicationId'] as String,
      medicationLogId: map['medicationLogId'] as String,
      patientUid: map['patientUid'] as String,
      medicationName: map['medicationName'] as String,
      dose: map['dose'] as String,
      instructions: map['instructions'] as String,
      scheduledTime: map['scheduledTime'] as String,
      scheduledDateTime: DateTime.parse(
        map['scheduledDateTime'] as String,
      ),
    );
  }
}