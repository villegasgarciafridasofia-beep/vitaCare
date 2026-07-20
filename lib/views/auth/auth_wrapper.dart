import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import 'login_view.dart';
import 'complete_profile_view.dart';
import 'routine_setup_view.dart';
import '../patient/patient_dashboard_view.dart';
import '../caregiver/caregiver_dashboard_view.dart';

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Mientras Firebase comprueba la sesión
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        // Error al comprobar la autenticación
        if (authSnapshot.hasError) {
          return const _ErrorView(
            message: 'No se pudo verificar la sesión.',
          );
        }

        final firebaseUser = authSnapshot.data;

        // No hay una sesión iniciada
        if (firebaseUser == null) {
          return const LoginView();
        }

        return FutureBuilder(
          future: firestoreService.getUser(firebaseUser.uid),
          builder: (context, userSnapshot) {
            // Mientras se obtiene el perfil de Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }

            // Error al consultar Firestore
            if (userSnapshot.hasError) {
              return const _ErrorView(
                message: 'No se pudo cargar la información del usuario.',
              );
            }

            final user = userSnapshot.data;

            // El usuario está autenticado, pero todavía no tiene perfil
            if (user == null) {
              return const CompleteProfileView();
            }

            // El perfil existe, pero todavía está incompleto
            if (!user.isProfileComplete) {
              return const CompleteProfileView();
            }

            // El perfil está completo, pero falta configurar la rutina
            if (!user.isRoutineConfigured) {
              return const RoutineSetupView();
            }

            // Navegación según el rol
            switch (user.role.toLowerCase().trim()) {
              case 'caregiver':
                return const CaregiverDashboardView();

              case 'both':
                return const PatientDashboardView();

              case 'patient':
              default:
                return const PatientDashboardView();
            }
          },
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}