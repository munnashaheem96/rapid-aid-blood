import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/emergency_alert_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final AudioPlayer player = AudioPlayer();

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  /// 🔔 FCM SETUP (NO OVERLAY)
  void setupFCM() async {
    await FirebaseMessaging.instance.requestPermission();

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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Rapid Aid",
      theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
      home: const SplashScreen(),
    );
  }
}
