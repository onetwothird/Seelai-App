import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart'; 
import 'package:flutter_callkit_incoming/entities/entities.dart'; // Make sure this is here!
import 'package:seelai_app/core/firebase_options.dart';
import 'package:seelai_app/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//copy
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Extract the new avatar URL from the payload
  final avatarUrl = message.data['callerAvatar'] ?? '';

  if (message.data['type'] == 'emergency_alarm') {
    final patientName = message.data['patientName'] ?? 'Patient';
    final requestMsg = message.data['message'] ?? 'Emergency Assistance Needed!';
    final requestId = message.data['requestId'] ?? 'req_${DateTime.now().millisecondsSinceEpoch}';

    final callParams = CallKitParams(
      id: requestId,
      // Keep name clean, no "EMERGENCY:" prefix looks much more professional
      nameCaller: patientName, 
      appName: 'SEELAI EMERGENCY', 
      avatar: avatarUrl, // <--- INJECTS THE PROFILE PICTURE
      handle: '🚨 $requestMsg', // Move the alert icon to the subtitle
      type: 0, 
      duration: 30000, 
      textAccept: 'Respond', // More professional than "Open App"
      textDecline: 'Dismiss',
      extra: <String, dynamic>{'requestId': requestId},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true, // Show the SEELAI app logo
        ringtonePath: 'system_ringtone_default', 
        backgroundColor: '#991B1B', // A professional, modern Deep Red (Tailwind Red 800)
        actionColor: '#10B981', // Professional modern Green
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        audioSessionMode: 'default',
        audioSessionActive: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    
    await FlutterCallkitIncoming.showCallkitIncoming(callParams);
  }
}

// ==========================================
// ADDED: The Permission Function
// ==========================================
Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: true,
    provisional: false,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // ==========================================
  // ADDED: Call the permission request here!
  // ==========================================
  await requestNotificationPermissions();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreenWidget(),
    );
  }
}