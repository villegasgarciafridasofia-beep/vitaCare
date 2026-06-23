import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/auth/auth_wrapper.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VitaCareApp());
}
//login
class VitaCareApp extends StatelessWidget {
  const VitaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaCare AI',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: AppRoutes.routes,
    );
  }
}