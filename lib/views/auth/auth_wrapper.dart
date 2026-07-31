import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/navigation_service.dart';
import '../caregiver/caregiver_dashboard_view.dart';
import '../patient/patient_dashboard_view.dart';
import 'complete_profile_view.dart';
import 'login_view.dart';
import 'routine_setup_view.dart';

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
          return const _ErrorView(message: 'No se pudo verificar la sesión.');
        }

        final User? firebaseUser = authSnapshot.data;

        // No hay una sesión iniciada
        if (firebaseUser == null) {
          NavigationService.resetAppReady();
          return const LoginView();
        }

        return FutureBuilder(
          future: firestoreService.getUser(firebaseUser.uid),
          builder: (context, userSnapshot) {
            // Mientras se obtiene el perfil
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

            // Usuario sin perfil
            if (user == null) {
              return const CompleteProfileView();
            }

            // Perfil incompleto
            if (!user.isProfileComplete) {
              return const CompleteProfileView();
            }

            final String role = user.role.toLowerCase().trim();

            // La rutina solo es obligatoria para paciente o perfil mixto.
            if (role != 'caregiver' && !user.isRoutineConfigured) {
              return const RoutineSetupView();
            }

            // Navegación según el rol
            switch (role) {
              case 'caregiver':
                return const _AppReadyView(child: CaregiverDashboardView());

              case 'both':
                return const _AppReadyView(child: PatientDashboardView());

              case 'patient':
              default:
                return const _AppReadyView(child: PatientDashboardView());
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _AppReadyView extends StatefulWidget {
  final Widget child;

  const _AppReadyView({required this.child});

  @override
  State<_AppReadyView> createState() => _AppReadyViewState();
}

class _AppReadyViewState extends State<_AppReadyView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.markAppReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
