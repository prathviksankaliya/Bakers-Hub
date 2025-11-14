import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      return await _localNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
    } else if (Platform.isAndroid) {
      PermissionStatus status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInitializationSetting = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(android: androidSettings, iOS: iosInitializationSetting);

    await _localNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: (response) {
      _handleNotificationClick(response.payload);
    });

    // NotificationSettings settings = await _firebaseMessaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    await requestPermissions();
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Listen to background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data['payload']);
    });

    // kill mode notification handle
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data['payload']);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'ehunt_notification_channel',
      'eHunt Channel',
      channelDescription: 'This channel is used for eHunt notification',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosNotificationDetails = DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true, presentBanner: true);

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);

    await _localNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data['payload'],
    );
  }

  void _handleNotificationClick(String? payload) async {
    if (payload != null) {
      final file = File(payload);
      if (await file.exists()) {
        OpenFile.open(payload);
      }
    }
  }

  Future<void> showManualNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'eHunt_manual_channel',
      'eHunt Manual Notifications',
      channelDescription: 'This channel is used for manual notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(presentBadge: true, presentAlert: true, presentSound: true, presentBanner: true, );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
