import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_settings_model.dart';

class UserSettingsService {
  UserSettingsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('user_settings');

  Future<UserSettingsModel> getSettings(String uid) async {
    final document = await _collection.doc(uid).get();
    final data = document.data();
    if (data == null) {
      final defaults = UserSettingsModel.defaults(uid);
      await saveSettings(defaults);
      return defaults;
    }
    return UserSettingsModel.fromMap(data);
  }

  Future<void> saveSettings(UserSettingsModel settings) async {
    await _collection.doc(settings.uid).set(
          settings.toMap(),
          SetOptions(merge: true),
        );
  }

  Stream<UserSettingsModel?> watchSettings(String uid) {
    return _collection.doc(uid).snapshots().map((document) {
      final data = document.data();
      return data == null ? null : UserSettingsModel.fromMap(data);
    });
  }
}
