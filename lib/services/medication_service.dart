import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addMedication(
      MedicationModel medication,
      ) async {
    await _db
        .collection('medications')
        .doc(medication.id)
        .set(
      medication.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<List<MedicationModel>> getPatientMedications(
      String patientUid,
      ) async {
    final query = await _db
        .collection('medications')
        .where(
      'patientUid',
      isEqualTo: patientUid,
    )
        .get();

    final medications = query.docs
        .map(
          (doc) => MedicationModel.fromMap(
        doc.data(),
      ),
    )
        .toList();

    medications.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return medications;
  }

  Future<MedicationModel?> getMedicationById(
      String medicationId,
      ) async {
    final document = await _db
        .collection('medications')
        .doc(medicationId)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return MedicationModel.fromMap(
      document.data()!,
    );
  }

  Future<void> updateMedication(
      MedicationModel medication,
      ) async {
    await _db
        .collection('medications')
        .doc(medication.id)
        .set(
      medication.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> deactivateMedication(
      String medicationId,
      ) async {
    await _db
        .collection('medications')
        .doc(medicationId)
        .set(
      {
        'active': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> activateMedication(
      String medicationId,
      ) async {
    await _db
        .collection('medications')
        .doc(medicationId)
        .set(
      {
        'active': true,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteMedication(
      String medicationId,
      ) async {
    await _db
        .collection('medications')
        .doc(medicationId)
        .delete();
  }
}