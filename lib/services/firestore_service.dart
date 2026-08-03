import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/routine_model.dart';
import '../models/medication_model.dart';
import 'routine_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RoutineService _routineService = RoutineService();

  // =====================================================
  // USUARIOS
  // =====================================================

  Future<void> saveUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUserRoutine({
    required String uid,
    required String wakeUpTime,
    required String breakfastTime,
    required String lunchTime,
    required String dinnerTime,
    required String sleepTime,
    required bool allowNightReminders,
    required int reminderMinutesBefore,
  }) async {
    final DateTime now = DateTime.now();

    await _db.collection('users').doc(uid).set(
      {
        'wakeUpTime': wakeUpTime,
        'breakfastTime': breakfastTime,
        'lunchTime': lunchTime,
        'dinnerTime': dinnerTime,
        'sleepTime': sleepTime,
        'allowNightReminders': allowNightReminders,
        'reminderMinutesBefore': reminderMinutesBefore,
        'isRoutineConfigured': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final RoutineModel routine = RoutineModel(
      uid: uid,
      wakeUpTime: wakeUpTime,
      breakfastTime: breakfastTime,
      lunchTime: lunchTime,
      dinnerTime: dinnerTime,
      sleepTime: sleepTime,
      allowNightReminders: allowNightReminders,
      reminderMinutesBefore: reminderMinutesBefore,
      isConfigured: true,
      createdAt: now,
      updatedAt: now,
    );

    await _routineService.saveRoutine(routine);
  }

  Future<void> markProfileAsComplete(String uid) async {
    await _db.collection('users').doc(uid).set(
      {
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<UserModel>> getPatients(List<String> patientIds) async {
    final List<UserModel> patients = [];

    for (final id in patientIds) {
      final doc = await _db.collection('users').doc(id).get();

      if (doc.exists && doc.data() != null) {
        patients.add(UserModel.fromMap(doc.data()!));
      }
    }

    return patients;
  }

  Future<List<UserModel>> getCaregivers(List<String> caregiverIds) async {
    final List<UserModel> caregivers = [];

    for (final id in caregiverIds) {
      final doc = await _db.collection('users').doc(id).get();

      if (doc.exists && doc.data() != null) {
        caregivers.add(UserModel.fromMap(doc.data()!));
      }
    }

    return caregivers;
  }

  Future<bool> userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  // =====================================================
  // MEDICAMENTOS
  // =====================================================

  Future<void> saveMedication(MedicationModel medication) async {
    await _db
        .collection('medications')
        .doc(medication.id)
        .set(medication.toMap());
  }

  Stream<List<MedicationModel>> getPatientMedications(String patientUid) {
    return _db
        .collection('medications')
        .where('patientUid', isEqualTo: patientUid)
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => MedicationModel.fromMap(doc.data()))
          .toList(),
    );
  }

  Future<void> updateMedication(MedicationModel medication) async {
    await _db
        .collection('medications')
        .doc(medication.id)
        .update(medication.toMap());
  }

  Future<void> deactivateMedication(String medicationId) async {
    await _db.collection('medications').doc(medicationId).update({
      'active': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}