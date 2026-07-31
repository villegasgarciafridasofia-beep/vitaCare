import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHistoryModel {
  final String id;
  final int notificationId;
  final String patientUid;
  final String title;
  final String body;
  final String type;
  final String status;
  final String? action;
  final String? medicationId;
  final String? medicationLogId;
  final String? medicationName;
  final bool isRead;
  final bool caregiverVisible;
  final DateTime scheduledAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationHistoryModel({
    required this.id,
    required this.notificationId,
    required this.patientUid,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    this.action,
    this.medicationId,
    this.medicationLogId,
    this.medicationName,
    required this.isRead,
    required this.caregiverVisible,
    required this.scheduledAt,
    this.deliveredAt,
    this.openedAt,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationId': notificationId,
      'patientUid': patientUid,
      'title': title,
      'body': body,
      'type': type,
      'status': status,
      'action': action,
      'medicationId': medicationId,
      'medicationLogId': medicationLogId,
      'medicationName': medicationName,
      'isRead': isRead,
      'caregiverVisible': caregiverVisible,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'deliveredAt': deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
      'openedAt': openedAt == null ? null : Timestamp.fromDate(openedAt!),
      'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NotificationHistoryModel.fromMap(Map<String, dynamic> map) {
    return NotificationHistoryModel(
      id: map['id']?.toString() ?? '',
      notificationId: _intFromValue(map['notificationId']),
      patientUid: map['patientUid']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      status: map['status']?.toString() ?? 'scheduled',
      action: map['action']?.toString(),
      medicationId: map['medicationId']?.toString(),
      medicationLogId: map['medicationLogId']?.toString(),
      medicationName: map['medicationName']?.toString(),
      isRead: map['isRead'] == true,
      caregiverVisible: map['caregiverVisible'] != false,
      scheduledAt: _dateFromValue(map['scheduledAt'] ?? map['createdAt']),
      deliveredAt: _nullableDateFromValue(map['deliveredAt']),
      openedAt: _nullableDateFromValue(map['openedAt']),
      readAt: _nullableDateFromValue(map['readAt']),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt'] ?? map['createdAt']),
    );
  }

  static int _intFromValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    return _dateFromValue(value);
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
