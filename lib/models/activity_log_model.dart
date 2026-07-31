import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String userUid;
  final String type;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    required this.userUid,
    required this.type,
    required this.description,
    required this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userUid': userUid,
      'type': type,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id']?.toString() ?? '',
      userUid: map['userUid']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      description: map['description']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(
        map['metadata'] is Map ? map['metadata'] as Map : const {},
      ),
      createdAt: _dateFromValue(map['createdAt']),
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
