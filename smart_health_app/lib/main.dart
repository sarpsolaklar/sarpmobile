import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smart_health_app/theme/app_theme.dart';
import 'package:smart_health_app/screens/splash_screen.dart';
import 'package:smart_health_app/screens/login_screen.dart';
import 'package:smart_health_app/screens/dashboard_screen.dart';
import 'package:smart_health_app/screens/add_medication_screen.dart';
import 'package:smart_health_app/screens/ai_assistant_screen.dart';
import 'package:smart_health_app/screens/maps_integration_screen.dart';
import 'package:smart_health_app/screens/privacy_screen.dart';
import 'package:smart_health_app/screens/scanner_screen.dart';
import 'package:smart_health_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();

  runApp(const SanctuaryHealthApp());
}

class SanctuaryHealthApp extends StatelessWidget {
  const SanctuaryHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanctuary Health',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add_medication': (context) => const AddMedicationScreen(),
        '/ai_assistant': (context) => const AIAssistantScreen(),
        '/maps': (context) => const MapsIntegrationScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/scanner': (context) => const ScannerScreen(),
      },
    );
  }
}
