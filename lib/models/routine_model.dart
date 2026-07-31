import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineModel {
  final String uid;
  final String wakeUpTime;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final String sleepTime;
  final bool allowNightReminders;
  final int reminderMinutesBefore;
  final bool isConfigured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineModel({
    required this.uid,
    required this.wakeUpTime,
    required this.breakfastTime,
    required this.lunchTime,
    required this.dinnerTime,
    required this.sleepTime,
    required this.allowNightReminders,
    required this.reminderMinutesBefore,
    required this.isConfigured,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'wakeUpTime': wakeUpTime,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'dinnerTime': dinnerTime,
      'sleepTime': sleepTime,
      'allowNightReminders': allowNightReminders,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isConfigured': isConfigured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RoutineModel.fromMap(Map<String, dynamic> map) {
    return RoutineModel(
      uid: map['uid']?.toString() ?? '',
      wakeUpTime: map['wakeUpTime']?.toString() ?? '',
      breakfastTime: map['breakfastTime']?.toString() ?? '',
      lunchTime: map['lunchTime']?.toString() ?? '',
      dinnerTime: map['dinnerTime']?.toString() ?? '',
      sleepTime: map['sleepTime']?.toString() ?? '',
      allowNightReminders: map['allowNightReminders'] == true,
      reminderMinutesBefore: _intFromValue(map['reminderMinutesBefore'], 10),
      isConfigured: map['isConfigured'] == true,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt'] ?? map['createdAt']),
    );
  }

  static int _intFromValue(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
