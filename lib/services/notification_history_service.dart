import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alarm_payload.dart';
import '../models/notification_history_model.dart';

class NotificationHistoryService {
  NotificationHistoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('notifications');

  String documentIdForNotification({
    required String patientUid,
    required int notificationId,
  }) {
    return '${patientUid}_$notificationId';
  }

  Future<void> saveScheduledMedicationNotification({
    required AlarmPayload payload,
    required String title,
    required String body,
    bool caregiverVisible = true,
  }) async {
    if (payload.patientUid.trim().isEmpty) return;

    final String documentId = documentIdForNotification(
      patientUid: payload.patientUid,
      notificationId: payload.notificationId,
    );
    final DateTime now = DateTime.now();

    final NotificationHistoryModel notification = NotificationHistoryModel(
      id: documentId,
      notificationId: payload.notificationId,
      patientUid: payload.patientUid,
      title: title,
      body: body,
      type: 'medication_alarm',
      status: 'scheduled',
      action: null,
      medicationId: payload.medicationId,
      medicationLogId: payload.medicationLogId,
      medicationName: payload.medicationName,
      isRead: false,
      caregiverVisible: caregiverVisible,
      scheduledAt: payload.scheduledDateTime,
      deliveredAt: null,
      openedAt: null,
      readAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await _collection.doc(documentId).set(
          notification.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> saveNotification({
    required String patientUid,
    required String title,
    required String body,
    required String type,
    String? medicationId,
    String? medicationLogId,
    String? medicationName,
    int notificationId = 0,
    DateTime? scheduledAt,
    bool caregiverVisible = true,
  }) async {
    if (patientUid.trim().isEmpty) return;

    final DocumentReference<Map<String, dynamic>> document =
        notificationId == 0
            ? _collection.doc()
            : _collection.doc(
                documentIdForNotification(
                  patientUid: patientUid,
                  notificationId: notificationId,
                ),
              );
    final DateTime now = DateTime.now();

    final NotificationHistoryModel notification = NotificationHistoryModel(
      id: document.id,
      notificationId: notificationId,
      patientUid: patientUid,
      title: title,
      body: body,
      type: type,
      status: 'created',
      action: null,
      medicationId: medicationId,
      medicationLogId: medicationLogId,
      medicationName: medicationName,
      isRead: false,
      caregiverVisible: caregiverVisible,
      scheduledAt: scheduledAt ?? now,
      deliveredAt: null,
      openedAt: null,
      readAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(notification.toMap(), SetOptions(merge: true));
  }

  Stream<List<NotificationHistoryModel>> watchRecentNotifications(
    String patientUid, {
    int limit = 30,
  }) {
    if (patientUid.trim().isEmpty) {
      return Stream<List<NotificationHistoryModel>>.value(const []);
    }

    return _collection
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => NotificationHistoryModel.fromMap(document.data()))
              .toList(),
        );
  }

  Future<List<NotificationHistoryModel>> getRecentNotifications(
    String patientUid, {
    int limit = 30,
  }) async {
    if (patientUid.trim().isEmpty) return [];

    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((document) => NotificationHistoryModel.fromMap(document.data()))
        .toList();
  }

  Future<void> markOpened({
    required String patientUid,
    required int notificationId,
  }) async {
    await _updateByNotificationId(
      patientUid: patientUid,
      notificationId: notificationId,
      values: {
        'status': 'opened',
        'isRead': true,
        'openedAt': FieldValue.serverTimestamp(),
        'readAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> markAction({
    required String patientUid,
    required int notificationId,
    required String action,
  }) async {
    await _updateByNotificationId(
      patientUid: patientUid,
      notificationId: notificationId,
      values: {
        'status': 'responded',
        'action': action,
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> markCancelled({
    required String patientUid,
    required int notificationId,
  }) async {
    await _updateByNotificationId(
      patientUid: patientUid,
      notificationId: notificationId,
      values: const {'status': 'cancelled'},
    );
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    await _collection.doc(notificationId).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String patientUid) async {
    if (patientUid.trim().isEmpty) return;

    final QuerySnapshot<Map<String, dynamic>> query = await _collection
        .where('patientUid', isEqualTo: patientUid)
        .where('isRead', isEqualTo: false)
        .get();

    if (query.docs.isEmpty) return;

    final WriteBatch batch = _db.batch();
    for (final document in query.docs) {
      batch.set(
        document.reference,
        {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    await _collection.doc(notificationId).delete();
  }

  Future<void> deleteAllNotifications(String patientUid) async {
    if (patientUid.trim().isEmpty) return;

    final QuerySnapshot<Map<String, dynamic>> query =
        await _collection.where('patientUid', isEqualTo: patientUid).get();
    if (query.docs.isEmpty) return;

    final WriteBatch batch = _db.batch();
    for (final document in query.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  Future<void> _updateByNotificationId({
    required String patientUid,
    required int notificationId,
    required Map<String, dynamic> values,
  }) async {
    if (patientUid.trim().isEmpty || notificationId == 0) return;

    final String documentId = documentIdForNotification(
      patientUid: patientUid,
      notificationId: notificationId,
    );

    await _collection.doc(documentId).set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
