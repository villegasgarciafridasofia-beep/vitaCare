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

  Map<String, dynamic> toJson() {
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

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory AlarmPayload.fromJson(Map<String, dynamic> json) {
    return AlarmPayload(
      notificationId: _parseInt(json['notificationId']),
      medicationId: json['medicationId']?.toString() ?? '',
      medicationLogId: json['medicationLogId']?.toString() ?? '',
      patientUid: json['patientUid']?.toString() ?? '',
      medicationName: json['medicationName']?.toString() ?? '',
      dose: json['dose']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
      scheduledTime: json['scheduledTime']?.toString() ?? '',
      scheduledDateTime: DateTime.parse(json['scheduledDateTime'].toString()),
    );
  }

  factory AlarmPayload.fromMap(Map<String, dynamic> map) {
    return AlarmPayload.fromJson(map);
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}
