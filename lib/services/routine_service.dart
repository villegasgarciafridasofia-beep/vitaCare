import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine_model.dart';

class RoutineService {
  RoutineService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _db.collection('routines');
  }

  Future<void> saveRoutine(RoutineModel routine) async {
    if (routine.uid.trim().isEmpty) {
      throw ArgumentError('El identificador del usuario está vacío.');
    }

    await _collection
        .doc(routine.uid)
        .set(routine.toMap(), SetOptions(merge: true));
  }

  Future<RoutineModel?> getRoutine(String uid) async {
    final String userId = uid.trim();

    if (userId.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document = await _collection
        .doc(userId)
        .get();

    final Map<String, dynamic>? data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    return RoutineModel.fromMap(data);
  }

  Stream<RoutineModel?> watchRoutine(String uid) {
    final String userId = uid.trim();

    if (userId.isEmpty) {
      return Stream<RoutineModel?>.value(null);
    }

    return _collection.doc(userId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> document,
    ) {
      final Map<String, dynamic>? data = document.data();

      if (!document.exists || data == null) {
        return null;
      }

      return RoutineModel.fromMap(data);
    });
  }
}
