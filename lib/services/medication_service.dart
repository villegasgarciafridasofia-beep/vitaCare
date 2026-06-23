import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Future<void> addMedication(
      MedicationModel medication) async {

    await _db
        .collection('medications')
        .doc(medication.id)
        .set(
      medication.toMap(),
    );
  }

  Future<List<MedicationModel>>
  getPatientMedications(
      String patientUid) async {

    final query =
    await _db
        .collection('medications')
        .where(
      'patientUid',
      isEqualTo: patientUid,
    )
        .get();

    return query.docs
        .map(
          (doc) => MedicationModel.fromMap(
        doc.data(),
      ),
    )
        .toList();
  }
}