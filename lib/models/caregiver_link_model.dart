import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverLinkModel {
  final String id;
  final String patientUid;
  final String caregiverUid;
  final String relationship;
  final String status;
  final bool viewMedications;
  final bool viewHistory;
  final bool receiveAlerts;
  final bool viewLocation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaregiverLinkModel({
    required this.id,
    required this.patientUid,
    required this.caregiverUid,
    required this.relationship,
    required this.status,
    required this.viewMedications,
    required this.viewHistory,
    required this.receiveAlerts,
    required this.viewLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientUid': patientUid,
      'caregiverUid': caregiverUid,
      'relationship': relationship,
      'status': status,
      'permissions': {
        'viewMedications': viewMedications,
        'viewHistory': viewHistory,
        'receiveAlerts': receiveAlerts,
        'viewLocation': viewLocation,
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CaregiverLinkModel.fromMap(Map<String, dynamic> map) {
    final permissions = Map<String, dynamic>.from(
      map['permissions'] is Map ? map['permissions'] as Map : const {},
    );

    return CaregiverLinkModel(
      id: map['id']?.toString() ?? '',
      patientUid: map['patientUid']?.toString() ?? '',
      caregiverUid: map['caregiverUid']?.toString() ?? '',
      relationship: map['relationship']?.toString() ?? 'Familiar',
      status: map['status']?.toString() ?? 'active',
      viewMedications: permissions['viewMedications'] != false,
      viewHistory: permissions['viewHistory'] != false,
      receiveAlerts: permissions['receiveAlerts'] != false,
      viewLocation: permissions['viewLocation'] == true,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt'] ?? map['createdAt']),
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
