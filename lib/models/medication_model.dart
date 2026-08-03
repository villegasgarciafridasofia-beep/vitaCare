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

  // Nuevos campos
  final bool firstDoseTaken;
  final DateTime? scheduleAnchorTime;

  final DateTime createdAt;
  final DateTime updatedAt;
// Información generada por IA

  final String sourceAI;
// manual | voice | image
  final double aiConfidence;
  final String? imageUrl;
  final String? laboratory;
  final String? registrationNumber;
  final String? aiRawText;
  final String? aiProvider;
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

    // Valores por defecto para no romper medicamentos antiguos
    this.firstDoseTaken = false,
    this.scheduleAnchorTime,

    required this.createdAt,
    required this.updatedAt,
    this.sourceAI = 'manual',

    this.aiConfidence = 0,

    this.imageUrl,

    this.laboratory,

    this.registrationNumber,

    this.aiRawText,

    this.aiProvider,
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
      'requiresCaregiverSupervision':
      requiresCaregiverSupervision,
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

      // Nuevos campos
      'firstDoseTaken': firstDoseTaken,
      'scheduleAnchorTime':
      scheduleAnchorTime?.toIso8601String(),

      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sourceAI':
      sourceAI,

      'aiConfidence':
      aiConfidence,

      'imageUrl':
      imageUrl,

      'laboratory':
      laboratory,

      'registrationNumber':
      registrationNumber,
      'aiRawText':
      aiRawText,

      'aiProvider':
      aiProvider,
    };
  }

  factory MedicationModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return MedicationModel(
      id: map['id'] ?? '',
      patientUid: map['patientUid'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      medicineForm: map['medicineForm'] ?? '',
      doseQuantity:
      map['doseQuantity'] != null
          ? (map['doseQuantity'] as num).toInt()
          : 1,
      doseUnit: map['doseUnit'] ?? '',
      isControlled: map['isControlled'] ?? false,
      requiresPrescription:
      map['requiresPrescription'] ?? false,
      requiresCaregiverSupervision:
      map['requiresCaregiverSupervision'] ?? false,
      priority: map['priority'] ?? 'Media',
      treatmentReason: map['treatmentReason'] ?? '',
      doctorName: map['doctorName'] ?? '',
      frequency: map['frequency'] ?? '',
      instructions: map['instructions'] ?? '',
      times:
      map['times'] != null
          ? List<String>.from(map['times'])
          : [],

      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),

      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : null,

      observations: map['observations'] ?? '',
      active: map['active'] ?? true,

      // Compatibilidad con registros anteriores
      firstDoseTaken:
      map['firstDoseTaken'] ?? false,

      scheduleAnchorTime:
      map['scheduleAnchorTime'] != null
          ? DateTime.parse(
        map['scheduleAnchorTime'],
      )
          : null,

      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),

      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      aiRawText:
      map['aiRawText'],

      aiProvider:
      map['aiProvider'],
    );
  }
  MedicationModel copyWith({

    String? name,
    String? medicineForm,
    int? doseQuantity,
    String? doseUnit,
    String? frequency,
    String? instructions,

    String? sourceAI,
    double? aiConfidence,
    String? aiRawText,
    String? aiProvider,

    String? imageUrl,
    String? laboratory,
    String? registrationNumber,

  }){

    return MedicationModel(

      id:id,
      patientUid:patientUid,

      name:name ?? this.name,

      category:category,

      medicineForm:
      medicineForm ?? this.medicineForm,

      doseQuantity:
      doseQuantity ?? this.doseQuantity,

      doseUnit:
      doseUnit ?? this.doseUnit,

      isControlled:
      isControlled,

      requiresPrescription:
      requiresPrescription,

      requiresCaregiverSupervision:
      requiresCaregiverSupervision,

      priority:
      priority,

      treatmentReason:
      treatmentReason,

      doctorName:
      doctorName,

      frequency:
      frequency ?? this.frequency,

      instructions:
      instructions ?? this.instructions,

      times:
      times,

      startDate:
      startDate,

      endDate:
      endDate,

      observations:
      observations,

      active:
      active,

      firstDoseTaken:
      firstDoseTaken,

      scheduleAnchorTime:
      scheduleAnchorTime,

      createdAt:
      createdAt,

      updatedAt:
      DateTime.now(),

      sourceAI:
      sourceAI ?? this.sourceAI,

      aiConfidence:
      aiConfidence ?? this.aiConfidence,

      imageUrl:
      imageUrl ?? this.imageUrl,

      laboratory:
      laboratory ?? this.laboratory,

      registrationNumber:
      registrationNumber ?? this.registrationNumber,

      aiRawText:
      aiRawText ?? this.aiRawText,

      aiProvider:
      aiProvider ?? this.aiProvider,


    );

  }
}