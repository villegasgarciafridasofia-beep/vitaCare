class MedicationAIResult {
  final String medicationName;
  final String dose;
  final String unit;
  final String frequency;
  final int durationDays;

  const MedicationAIResult({
    required this.medicationName,
    required this.dose,
    required this.unit,
    required this.frequency,
    required this.durationDays,
  });

  bool get isComplete =>
      medicationName.isNotEmpty &&
          dose.isNotEmpty &&
          frequency.isNotEmpty &&
          durationDays > 0;
}