import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final AudioPlayer player = AudioPlayer();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// 🔁 BACKGROUND FCM HANDLER
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Show emergency call-like Heads-Up / Full-Screen Intent Notification
  final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'emergency_alerts_v3',
    'Emergency Alerts 3.0',
    channelDescription: 'High-priority critical calling notification intents',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    playSound: true,
    ongoing: true,
    visibility: NotificationVisibility.public,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([500, 1000, 500, 1000, 500, 1000]),
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  final data = message.data;
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    "🚨 Emergency Call: ${data['bloodGroup'] ?? 'Blood'} Required",
    "${data['patientName'] ?? 'A patient'} requires immediate transfer at ${data['location'] ?? 'Trauma Center'}.",
    platformChannelSpecifics,
    payload: jsonEncode(data),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Android local notification configurations
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          final Map<String, dynamic> payload = jsonDecode(response.payload!);
          _routeToEmergencyAlert(payload);
        } catch (_) {}
      }
    },
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(const MyApp());
}

void _routeToEmergencyAlert(Map<String, dynamic> data) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => EmergencyAlertScreen(
        requestId: data['requestId'] ?? "",
        patientName: data['patientName'] ?? "Emergency Patient",
        bloodGroup: data['bloodGroup'] ?? "O-",
        units: data['units'] ?? "1",
        location: data['location'] ?? "Trauma Hospital Center",
        lat: data['lat'] ?? "0.0",
        lng: data['lng'] ?? "0.0",
        distance: data['distance'] ?? "2.8 km",
        urgency: data['urgency'] ?? "CRITICAL",
        createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
        hospitalId: data['hospitalId'] ?? "HOSP_01",
        eta: data['eta'] ?? "6",
        phone: data['phone'] ?? "108",
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    setupFCM();
  }

  /// 📍 LOCATION PERMISSION
  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }
    } else {
      await Geolocator.openAppSettings();
    }
  }

  /// 🔔 COMPLETE FCM SETUP
  Future<void> setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    String? token = await messaging.getToken();
    print("🔥 FCM registration token: $token");

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 4));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      final lat = pos?.latitude ?? 12.971598;
      final lng = pos?.longitude ?? 77.594562;

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "fcmToken": token,
        "lat": lat,
        "lng": lng,
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "fcmToken": newToken,
        }, SetOptions(merge: true));
      }
    });

    /// 📲 FOREGROUND ALERTS
    FirebaseMessaging.onMessage.listen((message) {
      _routeToEmergencyAlert(message.data);
    });

    /// 📲 BACKGROUND TAP ALERTS
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeToEmergencyAlert(message.data);
    });

    /// 📲 TERMINATED APP START ALERTS
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _routeToEmergencyAlert(initialMessage.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Rapid Aid",
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
