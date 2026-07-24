import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';
import 'views/auth/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------
  // 1. INICIALIZAR FIREBASE
  // ---------------------------------------------------------
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'Firebase inicializado correctamente.',
    );
  } catch (error, stackTrace) {
    debugPrint(
      'ERROR AL INICIALIZAR FIREBASE: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------
  // 2. MOSTRAR LA APLICACIÓN
  // ---------------------------------------------------------
  runApp(
    const VitaCareApp(),
  );

  // ---------------------------------------------------------
  // 3. INICIALIZAR SERVICIOS DE ANDROID
  // ---------------------------------------------------------
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    try {
      await AndroidAlarmManager.initialize();

      debugPrint(
        'AndroidAlarmManager inicializado correctamente.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'ERROR AL INICIALIZAR ANDROID ALARM MANAGER: '
            '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------
  // 4. INICIALIZAR NOTIFICACIONES
  // ---------------------------------------------------------
  if (!kIsWeb) {
    try {
      await NotificationService.instance.initialize();

      debugPrint(
        'NotificationService inicializado correctamente.',
      );




    } catch (error, stackTrace) {
      debugPrint(
        'ERROR AL INICIALIZAR NOTIFICACIONES: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }
}

class VitaCareApp extends StatelessWidget {
  const VitaCareApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaCare AI',

      debugShowCheckedModeBanner: false,

      navigatorKey: NavigationService.navigatorKey,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),

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
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(
              color: Colors.teal,
              width: 2,
            ),
          ),
        ),
      ),

      home: AuthWrapper(),

      routes: AppRoutes.routes,
    );
  }
}