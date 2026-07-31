import 'dart:async';
import 'views/splas/splash_view.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proyectovita/views/splas/splash_view.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';
import 'views/auth/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // 1. INICIALIZAR FIREBASE
  // =========================================================

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase inicializado correctamente.');
  } catch (error, stackTrace) {
    debugPrint('ERROR AL INICIALIZAR FIREBASE: $error');

    debugPrintStack(stackTrace: stackTrace);
  }

  // =========================================================
  // 2. INICIALIZAR ANDROID ALARM MANAGER
  // =========================================================

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final bool initialized = await AndroidAlarmManager.initialize();

      debugPrint('AndroidAlarmManager inicializado: $initialized');
    } catch (error, stackTrace) {
      debugPrint('ERROR AL INICIALIZAR ANDROID ALARM MANAGER: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // =========================================================
  // 3. INICIALIZAR NOTIFICACIONES
  // =========================================================

  if (!kIsWeb) {
    try {
      await NotificationService.instance.initialize();

      debugPrint('NotificationService inicializado correctamente.');
    } catch (error, stackTrace) {
      debugPrint('ERROR AL INICIALIZAR NOTIFICACIONES: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // =========================================================
  // 4. MOSTRAR LA APLICACIÓN
  // =========================================================

  runApp(const VitaCareApp());
}

class VitaCareApp extends StatefulWidget {
  const VitaCareApp({super.key});

  @override
  State<VitaCareApp> createState() => _VitaCareAppState();
}

class _VitaCareAppState extends State<VitaCareApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleInitialNotification());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      unawaited(NotificationService.instance.recoverActiveMedicationAlarm());
    }
  }

  Future<void> _handleInitialNotification() async {
    try {
      /*
       * Esperamos a que MaterialApp, AuthWrapper
       * y el Navigator terminen de construirse.
       */
      await NotificationService.instance.handleInitialNotification();
      await NotificationService.instance.recoverActiveMedicationAlarm();
    } catch (error, stackTrace) {
      debugPrint('Error procesando la notificación inicial: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaCare AI',
      debugShowCheckedModeBanner: false,

      navigatorKey: NavigationService.navigatorKey,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
      ),

      home: SplashView(),

      routes: AppRoutes.routes,
    );
  }
}
