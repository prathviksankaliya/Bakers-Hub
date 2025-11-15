import 'dart:io';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static final FirebaseOptions _android = FirebaseOptions(
    apiKey: dotenv.get("APP_ID", fallback: ""),
    appId: dotenv.get("API_KEY", fallback: ""),
    messagingSenderId: dotenv.get("MESSAGE_ID", fallback: ""),
    projectId: dotenv.get("PROJECT_ID", fallback: ""),
    storageBucket: dotenv.get("STORAGE_ID", fallback: ""),
  );

  static Future<void> init() async {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(options: _android);
    } else if (Platform.isIOS) {
      await Firebase.initializeApp();
    }
  }

  // Get FCM token
  static Future<String?> fetchAndSaveFcmToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      return await messaging.getToken();
    } catch (e) {
      print("Error fetching FCM token: $e");
    }
    return null;
  }
}
