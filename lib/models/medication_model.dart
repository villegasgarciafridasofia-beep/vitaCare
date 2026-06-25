class MedicationModel {
  final String id;
  final String patientUid;
  final String name;
  final String category;
  final String medicineForm;
  final int doseQuantity;
  final String doseUnit;
  final bool isControlled;
  final bool requiresPrescription;
  final bool requiresCaregiverSupervision;
  final String priority;
  final String treatmentReason;
  final String doctorName;
  final String frequency;
  final String instructions;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String observations;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationModel({
    required this.id,
    required this.patientUid,
    required this.name,
    required this.category,
    required this.medicineForm,
    required this.doseQuantity,
    required this.doseUnit,
    required this.isControlled,
    required this.requiresPrescription,
    required this.requiresCaregiverSupervision,
    required this.priority,
    required this.treatmentReason,
    required this.doctorName,
    required this.frequency,
    required this.instructions,
    required this.times,
    required this.startDate,
    this.endDate,
    required this.observations,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientUid': patientUid,
      'name': name,
      'category': category,
      'medicineForm': medicineForm,
      'doseQuantity': doseQuantity,
      'doseUnit': doseUnit,
      'isControlled': isControlled,
      'requiresPrescription': requiresPrescription,
      'requiresCaregiverSupervision': requiresCaregiverSupervision,
      'priority': priority,
      'treatmentReason': treatmentReason,
      'doctorName': doctorName,
      'frequency': frequency,
      'instructions': instructions,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'observations': observations,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'] ?? '',
      patientUid: map['patientUid'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      medicineForm: map['medicineForm'] ?? '',
      doseQuantity: map['doseQuantity'] ?? 1,
      doseUnit: map['doseUnit'] ?? '',
      isControlled: map['isControlled'] ?? false,
      requiresPrescription: map['requiresPrescription'] ?? false,
      requiresCaregiverSupervision:
      map['requiresCaregiverSupervision'] ?? false,
      priority: map['priority'] ?? 'Media',
      treatmentReason: map['treatmentReason'] ?? '',
      doctorName: map['doctorName'] ?? '',
      frequency: map['frequency'] ?? '',
      instructions: map['instructions'] ?? '',
      times: List<String>.from(map['times'] ?? []),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      observations: map['observations'] ?? '',
      active: map['active'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}