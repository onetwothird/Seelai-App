import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/core/firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase is already initialized, catch the error and continue
    if (e.toString().contains('duplicate-app')) {
    } else {
      // If it's a different error, rethrow it
      rethrow;
    }
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}