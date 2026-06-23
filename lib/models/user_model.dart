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

  final String role; // patient, caregiver o both

  final bool isProfileComplete;
  final bool isOlderAdult;

  final String authProvider; // email o google
  final String profileImage;
  final bool isActive;

  final String? linkCode;

  final List<String> caregivers;
  final List<String> patients;

  final DateTime createdAt;

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
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'paternalLastName': paternalLastName,
      'maternalLastName': maternalLastName,
      'birthDate': birthDate.toIso8601String(),
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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      paternalLastName: map['paternalLastName'] ?? '',
      maternalLastName: map['maternalLastName'] ?? '',
      birthDate: DateTime.parse(map['birthDate']),
      phoneNumber: map['phoneNumber'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      hasDisease: map['hasDisease'] ?? false,
      diseases: List<String>.from(map['diseases'] ?? []),
      role: map['role'] ?? 'patient',
      isProfileComplete: map['isProfileComplete'] ?? false,
      isOlderAdult: map['isOlderAdult'] ?? false,
      authProvider: map['authProvider'] ?? 'email',
      profileImage: map['profileImage'] ?? '',
      isActive: map['isActive'] ?? true,
      linkCode: map['linkCode'],
      caregivers: List<String>.from(map['caregivers'] ?? []),
      patients: List<String>.from(map['patients'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}