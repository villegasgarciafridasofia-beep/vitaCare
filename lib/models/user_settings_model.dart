import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsModel {
  final String uid;
  final bool notificationsEnabled;
  final bool alarmSoundEnabled;
  final bool vibrationEnabled;
  final String language;
  final String themeMode;
  final double textScale;
  final DateTime updatedAt;

  const UserSettingsModel({
    required this.uid,
    required this.notificationsEnabled,
    required this.alarmSoundEnabled,
    required this.vibrationEnabled,
    required this.language,
    required this.themeMode,
    required this.textScale,
    required this.updatedAt,
  });

  factory UserSettingsModel.defaults(String uid) {
    return UserSettingsModel(
      uid: uid,
      notificationsEnabled: true,
      alarmSoundEnabled: true,
      vibrationEnabled: true,
      language: 'es',
      themeMode: 'light',
      textScale: 1.0,
      updatedAt: DateTime.now(),
    );
  }

  UserSettingsModel copyWith({
    bool? notificationsEnabled,
    bool? alarmSoundEnabled,
    bool? vibrationEnabled,
    String? language,
    String? themeMode,
    double? textScale,
    DateTime? updatedAt,
  }) {
    return UserSettingsModel(
      uid: uid,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      alarmSoundEnabled: alarmSoundEnabled ?? this.alarmSoundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'notificationsEnabled': notificationsEnabled,
      'alarmSoundEnabled': alarmSoundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'language': language,
      'themeMode': themeMode,
      'textScale': textScale,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    final String uid = map['uid']?.toString() ?? '';
    return UserSettingsModel(
      uid: uid,
      notificationsEnabled: map['notificationsEnabled'] != false,
      alarmSoundEnabled: map['alarmSoundEnabled'] != false,
      vibrationEnabled: map['vibrationEnabled'] != false,
      language: map['language']?.toString() ?? 'es',
      themeMode: map['themeMode']?.toString() ?? 'light',
      textScale: _doubleFromValue(map['textScale'], 1.0),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static double _doubleFromValue(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
