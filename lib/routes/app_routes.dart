import 'package:flutter/material.dart';
import '../views/auth/routine_setup_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/complete_profile_view.dart';
import '../views/patient/patient_dashboard_view.dart';
import '../views/caregiver/caregiver_dashboard_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String completeProfile = '/complete-profile';
  static const String patientDashboard = '/patient-dashboard';
  static const String caregiverDashboard = '/caregiver-dashboard';
  static const String routineSetup = '/routine-setup';
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginView(),
    register: (context) => const RegisterView(),
    completeProfile: (context) => const CompleteProfileView(),
    patientDashboard: (context) => const PatientDashboardView(),
    caregiverDashboard: (context) => const CaregiverDashboardView(),
    routineSetup: (context) => const RoutineSetupView(),
  };
}