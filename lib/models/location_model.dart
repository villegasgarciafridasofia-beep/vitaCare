import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String patientUid;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;
  final bool isSharing;
  final DateTime updatedAt;

  const LocationModel({
    required this.patientUid,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.isSharing,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'patientUid': patientUid,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'isSharing': isSharing,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      patientUid: map['patientUid']?.toString() ?? '',
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      accuracy: _toDouble(map['accuracy']),
      altitude: _toDouble(map['altitude']),
      speed: _toDouble(map['speed']),
      heading: _toDouble(map['heading']),
      isSharing: map['isSharing'] ?? false,
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
