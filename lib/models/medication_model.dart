class MedicationModel {
  final String id;
  final String patientUid;

  final String name;
  final String dose;
  final String frequency;

  final List<String> times;

  final bool active;

  final DateTime createdAt;

  MedicationModel({
    required this.id,
    required this.patientUid,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.times,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientUid': patientUid,
      'name': name,
      'dose': dose,
      'frequency': frequency,
      'times': times,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromMap(
      Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'] ?? '',
      patientUid: map['patientUid'] ?? '',
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      frequency: map['frequency'] ?? '',
      times: List<String>.from(map['times'] ?? []),
      active: map['active'] ?? true,
      createdAt:
      DateTime.parse(map['createdAt']),
    );
  }
}