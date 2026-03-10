import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seelai_app/core/firebase_options.dart';
import 'package:seelai_app/screens/splash_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
    } else {
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
      home: const AnimatedSplashScreenWidget(),
    );
  }
}