import 'package:cloud_firestore/cloud_firestore.dart';

class LinkingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _linkId({
    required String patientUid,
    required String caregiverUid,
  }) {
    return '${patientUid}_$caregiverUid';
  }

  Future<void> linkPatientAndCaregiver({
    required String patientUid,
    required String caregiverUid,
    String relationship = 'Familiar',
  }) async {
    final String patientId = patientUid.trim();
    final String caregiverId = caregiverUid.trim();

    if (patientId.isEmpty || caregiverId.isEmpty) {
      throw Exception(
        'El código de vinculación no es válido.',
      );
    }

    if (patientId == caregiverId) {
      throw Exception(
        'No puedes vincular tu propia cuenta.',
      );
    }

    final DocumentReference<Map<String, dynamic>> patientRef =
    _db.collection('users').doc(patientId);

    final DocumentReference<Map<String, dynamic>> caregiverRef =
    _db.collection('users').doc(caregiverId);

    final DocumentReference<Map<String, dynamic>> linkRef =
    _db.collection('caregiver_links').doc(
      _linkId(
        patientUid: patientId,
        caregiverUid: caregiverId,
      ),
    );

    await _db.runTransaction<void>(
          (
          Transaction transaction,
          ) async {
        /*
         * Todas las lecturas se realizan antes
         * de comenzar las escrituras.
         */
        final DocumentSnapshot<Map<String, dynamic>>
        patientDocument = await transaction.get(
          patientRef,
        );

        final DocumentSnapshot<Map<String, dynamic>>
        caregiverDocument = await transaction.get(
          caregiverRef,
        );

        final DocumentSnapshot<Map<String, dynamic>>
        linkDocument = await transaction.get(
          linkRef,
        );

        final Map<String, dynamic>? patientData =
        patientDocument.data();

        final Map<String, dynamic>? caregiverData =
        caregiverDocument.data();

        final Map<String, dynamic>? linkData =
        linkDocument.data();

        if (!patientDocument.exists ||
            patientData == null) {
          throw Exception(
            'No se encontró al paciente.',
          );
        }

        if (!caregiverDocument.exists ||
            caregiverData == null) {
          throw Exception(
            'No se encontró el perfil del familiar.',
          );
        }

        final String patientRole =
        (patientData['role'] ?? 'patient')
            .toString()
            .toLowerCase()
            .trim();

        final String caregiverRole =
        (caregiverData['role'] ?? 'caregiver')
            .toString()
            .toLowerCase()
            .trim();

        if (patientRole != 'patient' &&
            patientRole != 'both') {
          throw Exception(
            'El código no pertenece a un paciente.',
          );
        }

        if (caregiverRole != 'caregiver' &&
            caregiverRole != 'both') {
          throw Exception(
            'Tu perfil debe ser de familiar o cuidador.',
          );
        }

        final List<String> caregivers =
        List<String>.from(
          patientData['caregivers'] ?? <String>[],
        );

        final List<String> patients =
        List<String>.from(
          caregiverData['patients'] ?? <String>[],
        );

        final String existingStatus =
        (linkData?['status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

        final bool activeLinkAlreadyExists =
            linkDocument.exists &&
                existingStatus == 'active';

        if (caregivers.contains(caregiverId) ||
            activeLinkAlreadyExists) {
          throw Exception(
            'Este paciente ya está vinculado contigo.',
          );
        }

        if (caregivers.length >= 3) {
          throw Exception(
            'El paciente ya alcanzó el máximo de 3 familiares.',
          );
        }

        caregivers.add(caregiverId);

        if (!patients.contains(patientId)) {
          patients.add(patientId);
        }

        final Object createdAtValue;

        if (linkDocument.exists &&
            linkData?['createdAt'] != null) {
          createdAtValue = linkData!['createdAt'];
        } else {
          createdAtValue =
              FieldValue.serverTimestamp();
        }

        transaction.set(
          patientRef,
          <String, dynamic>{
            'caregivers': caregivers,
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        transaction.set(
          caregiverRef,
          <String, dynamic>{
            'patients': patients,
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        transaction.set(
          linkRef,
          <String, dynamic>{
            'id': linkRef.id,
            'patientUid': patientId,
            'caregiverUid': caregiverId,
            'relationship':
            relationship.trim().isEmpty
                ? 'Familiar'
                : relationship.trim(),
            'status': 'active',
            'permissions': <String, bool>{
              'viewMedications': true,
              'viewHistory': true,
              'receiveAlerts': true,
              'viewLocation': false,
            },
            'createdAt': createdAtValue,
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      },
    );
  }

  Future<void> unlinkPatientAndCaregiver({
    required String patientUid,
    required String caregiverUid,
  }) async {
    final String patientId = patientUid.trim();
    final String caregiverId = caregiverUid.trim();

    if (patientId.isEmpty || caregiverId.isEmpty) {
      throw ArgumentError(
        'Los identificadores del paciente y del cuidador son obligatorios.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
    patientRef =
    _db.collection('users').doc(patientId);

    final DocumentReference<Map<String, dynamic>>
    caregiverRef =
    _db.collection('users').doc(caregiverId);

    final DocumentReference<Map<String, dynamic>>
    linkRef =
    _db.collection('caregiver_links').doc(
      _linkId(
        patientUid: patientId,
        caregiverUid: caregiverId,
      ),
    );

    final WriteBatch batch = _db.batch();

    batch.set(
      patientRef,
      <String, dynamic>{
        'caregivers': FieldValue.arrayRemove(
          <String>[caregiverId],
        ),
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.set(
      caregiverRef,
      <String, dynamic>{
        'patients': FieldValue.arrayRemove(
          <String>[patientId],
        ),
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.set(
      linkRef,
      <String, dynamic>{
        'status': 'revoked',
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await batch.commit();
  }
}