import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'activity_log_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityLogService _activityLogService = ActivityLogService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _safeActivity(
      userUid: credential.user?.uid,
      type: 'account_registered',
      description: 'La cuenta fue registrada con correo y contraseña.',
      metadata: {'provider': 'email'},
    );

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _safeActivity(
      userUid: credential.user?.uid,
      type: 'login',
      description: 'Inicio de sesión con correo y contraseña.',
      metadata: {'provider': 'email'},
    );

    return credential;
  }

  Future<UserCredential> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('Inicio de sesión cancelado');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);

    await _safeActivity(
      userUid: result.user?.uid,
      type: 'login',
      description: 'Inicio de sesión con Google.',
      metadata: {'provider': 'google'},
    );

    return result;
  }

  Future<void> logout() async {
    final String? uid = _auth.currentUser?.uid;

    await _safeActivity(
      userUid: uid,
      type: 'logout',
      description: 'El usuario cerró la sesión.',
    );

    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<void> _safeActivity({
    required String? userUid,
    required String type,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (userUid == null || userUid.trim().isEmpty) return;

    try {
      await _activityLogService.register(
        userUid: userUid,
        type: type,
        description: description,
        metadata: metadata,
      );
    } catch (_) {
      // Un fallo en la bitácora nunca debe bloquear el acceso del usuario.
    }
  }
}
