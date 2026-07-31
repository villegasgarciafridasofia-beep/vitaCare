import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/caregiver_link_model.dart';

class CaregiverLinkService {
  CaregiverLinkService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('caregiver_links');

  String linkId({
    required String patientUid,
    required String caregiverUid,
  }) {
    return '${patientUid}_$caregiverUid';
  }

  Future<CaregiverLinkModel?> getLink({
    required String patientUid,
    required String caregiverUid,
  }) async {
    final document = await _collection
        .doc(linkId(patientUid: patientUid, caregiverUid: caregiverUid))
        .get();
    final data = document.data();
    return data == null ? null : CaregiverLinkModel.fromMap(data);
  }

  Future<List<CaregiverLinkModel>> getPatientLinks(String patientUid) async {
    final query = await _collection
        .where('patientUid', isEqualTo: patientUid)
        .where('status', isEqualTo: 'active')
        .get();

    return query.docs
        .map((document) => CaregiverLinkModel.fromMap(document.data()))
        .toList();
  }

  Future<List<CaregiverLinkModel>> getCaregiverLinks(
    String caregiverUid,
  ) async {
    final query = await _collection
        .where('caregiverUid', isEqualTo: caregiverUid)
        .where('status', isEqualTo: 'active')
        .get();

    return query.docs
        .map((document) => CaregiverLinkModel.fromMap(document.data()))
        .toList();
  }
}
