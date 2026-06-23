import 'package:cloud_firestore/cloud_firestore.dart';

class LinkingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> linkPatientAndCaregiver({
    required String patientUid,
    required String caregiverUid,
  }) async {

    final patientRef =
    _db.collection('users').doc(patientUid);

    final caregiverRef =
    _db.collection('users').doc(caregiverUid);

    final patientDoc = await patientRef.get();

    if (!patientDoc.exists) {
      throw Exception('Paciente no encontrado');
    }

    final caregivers =
    List<String>.from(patientDoc['caregivers'] ?? []);

    if (caregivers.contains(caregiverUid)) {
      throw Exception('Ya está vinculado');
    }

    if (caregivers.length >= 3) {
      throw Exception(
        'El paciente ya tiene 3 cuidadores',
      );
    }

    await patientRef.update({
      'caregivers': FieldValue.arrayUnion([
        caregiverUid
      ])
    });

    await caregiverRef.update({
      'patients': FieldValue.arrayUnion([
        patientUid
      ])
    });
  }
}