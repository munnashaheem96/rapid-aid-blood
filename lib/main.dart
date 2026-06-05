import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final AudioPlayer player = AudioPlayer();

/// 🔥 BACKGROUND HANDLER
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("📩 Background message: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(const MyApp());
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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
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
    print("🔥 TOKEN: $token");

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && token != null) {
      Position pos = await Geolocator.getCurrentPosition();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "fcmToken": token,
        "lat": pos.latitude,
        "lng": pos.longitude,
        "bloodGroup": "A+", // 🔴 replace with actual user value
      }, SetOptions(merge: true));
    }

    /// 🔁 TOKEN REFRESH (critical)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "fcmToken": newToken,
        }, SetOptions(merge: true));
      }
    });

    /// 📲 FOREGROUND
    FirebaseMessaging.onMessage.listen((message) async {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sounds/emergency.mp3'));

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EmergencyAlertScreen(
            bloodGroup: message.data['bloodGroup'] ?? "Unknown",
            location: message.data['location'] ?? "Nearby",
            phone: message.data['phone'] ?? "0000000000",
          ),
        ),
      );
    });

    /// 📲 BACKGROUND TAP
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EmergencyAlertScreen(
            bloodGroup: message.data['bloodGroup'] ?? "Unknown",
            location: message.data['location'] ?? "Nearby",
            phone: message.data['phone'] ?? "0000000000",
          ),
        ),
      );
    });

    /// 📲 TERMINATED
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EmergencyAlertScreen(
            bloodGroup: initialMessage.data['bloodGroup'] ?? "Unknown",
            location: initialMessage.data['location'] ?? "Nearby",
            phone: initialMessage.data['phone'] ?? "0000000000",
          ),
        ),
      );
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
