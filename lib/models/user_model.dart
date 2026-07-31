import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;

  final String name;
  final String paternalLastName;
  final String maternalLastName;
  final DateTime birthDate;

  final String phoneNumber;
  final String emergencyContact;

  final bool hasDisease;
  final List<String> diseases;

  final String role;

  final bool isProfileComplete;
  final bool isOlderAdult;

  final String authProvider;
  final String profileImage;
  final bool isActive;

  final String? linkCode;

  final List<String> caregivers;
  final List<String> patients;

  final DateTime createdAt;

  final String wakeUpTime;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final String sleepTime;

  final bool allowNightReminders;
  final int reminderMinutesBefore;
  final bool isRoutineConfigured;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.paternalLastName,
    required this.maternalLastName,
    required this.birthDate,
    required this.phoneNumber,
    required this.emergencyContact,
    required this.hasDisease,
    required this.diseases,
    required this.role,
    required this.isProfileComplete,
    required this.isOlderAdult,
    required this.authProvider,
    required this.profileImage,
    required this.isActive,
    this.linkCode,
    required this.caregivers,
    required this.patients,
    required this.createdAt,
    this.wakeUpTime = '',
    this.breakfastTime = '',
    this.lunchTime = '',
    this.dinnerTime = '',
    this.sleepTime = '',
    this.allowNightReminders = false,
    this.reminderMinutesBefore = 10,
    this.isRoutineConfigured = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'paternalLastName': paternalLastName,
      'maternalLastName': maternalLastName,
      'birthDate': Timestamp.fromDate(birthDate),
      'phoneNumber': phoneNumber,
      'emergencyContact': emergencyContact,
      'hasDisease': hasDisease,
      'diseases': diseases,
      'role': role,
      'isProfileComplete': isProfileComplete,
      'isOlderAdult': isOlderAdult,
      'authProvider': authProvider,
      'profileImage': profileImage,
      'isActive': isActive,
      'linkCode': linkCode,
      'caregivers': caregivers,
      'patients': patients,
      'createdAt': Timestamp.fromDate(createdAt),
      'wakeUpTime': wakeUpTime,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'dinnerTime': dinnerTime,
      'sleepTime': sleepTime,
      'allowNightReminders': allowNightReminders,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isRoutineConfigured': isRoutineConfigured,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      paternalLastName:
      map['paternalLastName']?.toString() ?? '',
      maternalLastName:
      map['maternalLastName']?.toString() ?? '',
      birthDate: _dateFromValue(map['birthDate']),
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      emergencyContact:
      map['emergencyContact']?.toString() ?? '',
      hasDisease: map['hasDisease'] ?? false,
      diseases: List<String>.from(
        map['diseases'] ?? <String>[],
      ),
      role: map['role']?.toString() ?? 'patient',
      isProfileComplete:
      map['isProfileComplete'] ?? false,
      isOlderAdult: map['isOlderAdult'] ?? false,
      authProvider:
      map['authProvider']?.toString() ?? 'email',
      profileImage:
      map['profileImage']?.toString() ?? '',
      isActive: map['isActive'] ?? true,
      linkCode: map['linkCode']?.toString(),
      caregivers: List<String>.from(
        map['caregivers'] ?? <String>[],
      ),
      patients: List<String>.from(
        map['patients'] ?? <String>[],
      ),
      createdAt: _dateFromValue(map['createdAt']),
      wakeUpTime:
      map['wakeUpTime']?.toString() ?? '',
      breakfastTime:
      map['breakfastTime']?.toString() ?? '',
      lunchTime:
      map['lunchTime']?.toString() ?? '',
      dinnerTime:
      map['dinnerTime']?.toString() ?? '',
      sleepTime:
      map['sleepTime']?.toString() ?? '',
      allowNightReminders:
      map['allowNightReminders'] ?? false,
      reminderMinutesBefore:
      map['reminderMinutesBefore'] ?? 10,
      isRoutineConfigured:
      map['isRoutineConfigured'] ?? false,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now();
    }

    return DateTime.now();
  }
}