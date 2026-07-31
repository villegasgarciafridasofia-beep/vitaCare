import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log_model.dart';

class ActivityLogService {
  ActivityLogService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('activity_logs');

  Future<void> register({
    required String userUid,
    required String type,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (userUid.trim().isEmpty) return;

    final document = _collection.doc();
    final log = ActivityLogModel(
      id: document.id,
      userUid: userUid,
      type: type,
      description: description,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    await document.set(log.toMap());
  }

  Future<List<ActivityLogModel>> getRecentActivity(
    String userUid, {
    int limit = 30,
  }) async {
    if (userUid.trim().isEmpty) return [];

    final query = await _collection
        .where('userUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((document) => ActivityLogModel.fromMap(document.data()))
        .toList();
  }
}
