// lib/services/ai/medication_ai_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationAIService {
  static final MedicationAIService _instance = MedicationAIService._internal();
  factory MedicationAIService() => _instance;
  MedicationAIService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Procesa el texto de voz y extrae información del medicamento
  MedicationAIResult processVoiceText(String text) {
    final result = MedicationAIResult(
      rawText: text,
      medicationName: _extractMedicationName(text),
      dosage: _extractDosage(text),
      frequency: _extractFrequency(text),
      presentation: _extractPresentation(text),
      confidence: _calculateConfidence(text),
    );

    return result;
  }

  String _extractMedicationName(String text) {
    // Lista común de medicamentos en México
    final commonMedications = [
      'paracetamol', 'ibuprofeno', 'aspirina', 'metformina', 'losartán',
      'omeprazol', 'levotiroxina', 'atorvastatina', 'enalapril', 'amoxicilina',
      'cetirizina', 'prednisona', 'sertralina', 'vitamina', 'complejo b'
    ];

    String lowerText = text.toLowerCase();

    for (String med in commonMedications) {
      if (lowerText.contains(med)) {
        return med;
      }
    }

    // Patrones de búsqueda
    final patterns = [
      r'(?:medicamento|tomo|necesito|receta|tabletas?|pastillas?|inyección)\s+([a-záéíóúñ]+)',
      r'([a-záéíóúñ]+)\s+(?:mg|ml|g|mcg|ui)',
    ];

    for (String pattern in patterns) {
      RegExp regExp = RegExp(pattern, caseSensitive: false);
      var match = regExp.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }

    return 'Medicamento no identificado';
  }

  String _extractDosage(String text) {
    final pattern = r'(\d+)\s*(?:mg|ml|g|mcg|ui|miligramos|mililitros|gramos)';
    RegExp regExp = RegExp(pattern, caseSensitive: false);
    var match = regExp.firstMatch(text);

    if (match != null) {
      return match.group(0)!;
    }

    // Patrones alternativos
    final altPattern = r'(\d+)\s*(?:tableta|pastilla|gota)';
    RegExp altRegExp = RegExp(altPattern, caseSensitive: false);
    var altMatch = altRegExp.firstMatch(text);

    if (altMatch != null) {
      return '${altMatch.group(1)} unidad(es)';
    }

    return 'Dosis no especificada';
  }

  String _extractFrequency(String text) {
    final frequencies = {
      r'cada\s+(\d+)\s+horas': (match) => 'Cada ${match.group(1)} horas',
      r'cada\s+(\d+)\s+días': (match) => 'Cada ${match.group(1)} días',
      r'(\d+)\s+vez(?:es)?\s+al\s+día': (match) => '${match.group(1)} veces al día',
      r'(una|dos|tres|cuatro|cada)\s+vez': (match) => _normalizeFrequency(match.group(1)),
    };

    for (var entry in frequencies.entries) {
      RegExp regExp = RegExp(entry.key, caseSensitive: false);
      var match = regExp.firstMatch(text);
      if (match != null) {
        return entry.value(match);
      }
    }

    return 'Frecuencia no especificada';
  }

  String _normalizeFrequency(String? value) {
    final map = {
      'una': '1 vez al día',
      'dos': '2 veces al día',
      'tres': '3 veces al día',
      'cuatro': '4 veces al día',
      'cada': 'Cada vez que sea necesario',
    };
    return map[value?.toLowerCase()] ?? 'Frecuencia no especificada';
  }

  String _extractPresentation(String text) {
    final presentations = [
      'tabletas', 'pastillas', 'cápsulas', 'grajeas', 'comprimidos',
      'gotas', 'solución', 'suspensión', 'inyección', 'ampolla',
      'crema', 'ungüento', 'pomada', 'gel', 'parche', 'polvo', 'jarabe'
    ];

    String lowerText = text.toLowerCase();

    for (String present in presentations) {
      if (lowerText.contains(present)) {
        return present;
      }
    }

    return 'Presentación no especificada';
  }

  double _calculateConfidence(String text) {
    double confidence = 0.5; // Base

    // Factores que aumentan la confianza
    if (_extractMedicationName(text) != 'Medicamento no identificado') confidence += 0.2;
    if (_extractDosage(text) != 'Dosis no especificada') confidence += 0.1;
    if (_extractFrequency(text) != 'Frecuencia no especificada') confidence += 0.1;
    if (_extractPresentation(text) != 'Presentación no especificada') confidence += 0.05;

    // Si el texto es muy corto, reducir confianza
    if (text.length < 10) confidence -= 0.2;

    return confidence.clamp(0.0, 1.0);
  }

  /// Guarda el medicamento en Firestore
  Future<void> saveMedication(MedicationAIResult result, String patientId) async {
    try {
      await _firestore.collection('medications').add({
        'patientId': patientId,
        'name': result.medicationName,
        'dosage': result.dosage,
        'frequency': result.frequency,
        'presentation': result.presentation,
        'rawText': result.rawText,
        'confidence': result.confidence,
        'source': 'voice',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'adherence': 0.0,
        'totalDays': 0,
        'takenDays': 0,
      });
    } catch (e) {
      throw Exception('Error al guardar medicamento: $e');
    }
  }

  /// Obtiene sugerencias de medicamentos basadas en lo que el usuario dijo
  Future<List<String>> getMedicationSuggestions(String partialText) async {
    // Esto podría llamar a una API externa o usar una lista local
    final commonMedications = [
      'Paracetamol 500mg',
      'Ibuprofeno 400mg',
      'Metformina 850mg',
      'Losartán 50mg',
      'Omeprazol 20mg',
      'Levotiroxina 50mcg',
      'Atorvastatina 20mg',
      'Enalapril 10mg',
      'Amoxicilina 500mg',
      'Cetirizina 10mg',
    ];

    return commonMedications
        .where((med) => med.toLowerCase().contains(partialText.toLowerCase()))
        .toList();
  }
}

/// Modelo de resultado de IA
class MedicationAIResult {
  final String rawText;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String presentation;
  final double confidence;

  MedicationAIResult({
    required this.rawText,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.presentation,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'rawText': rawText,
    'medicationName': medicationName,
    'dosage': dosage,
    'frequency': frequency,
    'presentation': presentation,
    'confidence': confidence,
  };
}