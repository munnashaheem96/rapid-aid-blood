import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class FamilySosScreen extends StatefulWidget {
  const FamilySosScreen({super.key});

  @override
  State<FamilySosScreen> createState() => _FamilySosScreenState();
}

class _FamilySosScreenState extends State<FamilySosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  StreamSubscription<Position>? _positionSubscription;
  bool _isSosTriggered = false;
  String _statusText = "Ready to broadcast distress signal";
  
  // Custom contacts configuration
  final List<Map<String, String>> _familyContacts = [
    {"name": "Mom (Primary)", "phone": "9876543210"},
    {"name": "Dad (Secondary)", "phone": "9876543211"},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _triggerFamilySos() async {
    if (_isSosTriggered) {
      _cancelFamilySos();
      return;
    }

    setState(() {
      _isSosTriggered = true;
      _statusText = "SOS ACTIVE! Broadcasting live updates...";
    });

    // 1. Fire emergency 108 call
    final Uri phoneUri = Uri(scheme: 'tel', path: '108');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }

    // 2. Continuous location tracking (high accuracy)
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Send updates every 5 meters
      ),
    ).listen((Position position) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Broadcast telemetry to Firestore logs
        await FirebaseFirestore.instance.collection("logs").add({
          "uid": user.uid,
          "type": "family_sos",
          "lat": position.latitude,
          "lng": position.longitude,
          "battery": 82, // Hardcoded typical battery telemetry for mockup
          "createdAt": Timestamp.now(),
        });

        // Update the active tracking document for family members
        await FirebaseFirestore.instance.collection("active_trackers").doc(user.uid).set({
          "lat": position.latitude,
          "lng": position.longitude,
          "battery": 82,
          "updatedAt": Timestamp.now(),
          "contacts": _familyContacts,
          "status": "SOS_ACTIVE"
        });
      }
    });

    // 3. Notify family contacts via mock SMS/Push log
    for (var contact in _familyContacts) {
      print("🚨 Dispatching SMS Alert to ${contact['name']}: Emergency triggered! View tracking: https://munnashaheem96.github.io/rapid-aid-card/user.html");
    }
  }

  Future<void> _cancelFamilySos() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("active_trackers").doc(user.uid).delete();
    }

    setState(() {
      _isSosTriggered = false;
      _statusText = "Ready to broadcast distress signal";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Emergency SOS canceled.", style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.charcoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Family SOS Guardian",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              Text(
                "SECURE FAMILY EMERGENCY BEACON",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _isSosTriggered ? AppTheme.primary : Colors.indigo.shade800,
                  letterSpacing: 1.0
                ),
              ),
              const SizedBox(height: 10),
              
              Text(
                "Tapping the shield immediately dials 108, triggers continuous telemetry logs, and alerts registered family members with a live tracking portal.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5
                ),
              ),

              const Expanded(child: SizedBox()),

              // Pulsing SOS Trigger Button
              Center(
                child: GestureDetector(
                  onTap: _triggerFamilySos,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      double scale = 1.0 + (_pulseController.value * 0.15);
                      return Transform.scale(
                        scale: _isSosTriggered ? scale : 1.0,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSosTriggered ? AppTheme.primaryDark : Colors.indigo.shade700,
                        boxShadow: [
                          BoxShadow(
                            color: _isSosTriggered 
                                ? AppTheme.primary.withOpacity(0.6)
                                : Colors.indigo.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSosTriggered ? Icons.emergency : Icons.shield_outlined,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isSosTriggered ? "CANCEL SOS" : "ACTIVATE",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.8
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Expanded(child: SizedBox()),

              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSosTriggered ? Icons.radar_outlined : Icons.check_circle_outline,
                          color: _isSosTriggered ? AppTheme.primary : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    if (_isSosTriggered) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(color: AppTheme.primary)
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Emergency contacts list
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Notified Family Members:",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain),
                ),
              ),
              const SizedBox(height: 8),

              ..._familyContacts.map((contact) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(contact["name"]!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(contact["phone"]!, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
