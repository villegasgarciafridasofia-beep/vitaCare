import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  Future<List<UserModel>> getPatients(List<String> patientIds) async {
    List<UserModel> patients = [];

    for (String id in patientIds) {
      final doc = await _db.collection('users').doc(id).get();

      if (doc.exists) {
        patients.add(
          UserModel.fromMap(doc.data()!),
        );
      }
    }

    return patients;
  }
  Future<List<UserModel>> getCaregivers(
      List<String> caregiverIds) async {

    List<UserModel> caregivers = [];

    for (String id in caregiverIds) {

      final doc =
      await _db.collection('users').doc(id).get();

      if (doc.exists) {
        caregivers.add(
          UserModel.fromMap(doc.data()!),
        );
      }
    }

    return caregivers;
  }
  Future<bool> userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }
}