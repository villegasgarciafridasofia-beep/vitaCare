import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import '../auth/login_view.dart';
import '../auth/complete_profile_view.dart';
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
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authSnapshot.data == null) {
          return const LoginView();
        }

        return FutureBuilder(
          future: firestoreService.getUser(authSnapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final user = userSnapshot.data;

            if (user == null) {
              return const CompleteProfileView();
            }

            if (!user.isProfileComplete) {
              return const CompleteProfileView();
            }

            switch (user.role) {
              case 'caregiver':
                return const CaregiverDashboardView();

              case 'both':
                return const PatientDashboardView();

              default:
                return const PatientDashboardView();
            }
          },
        );
      },
    );
  }
}