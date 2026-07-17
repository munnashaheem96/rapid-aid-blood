import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final String requestId;
  final String patientName;
  final String bloodGroup;
  final String units;
  final String location;
  final String lat;
  final String lng;
  final String distance;
  final String urgency;
  final String createdAt;
  final String hospitalId;
  final String eta;
  final String phone;

  const EmergencyAlertScreen({
    super.key,
    required this.requestId,
    required this.patientName,
    required this.bloodGroup,
    required this.units,
    required this.location,
    required this.lat,
    required this.lng,
    required this.distance,
    required this.urgency,
    required this.createdAt,
    required this.hospitalId,
    required this.eta,
    required this.phone,
  });

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Timer & Countdown
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  String _timeElapsed = "0s ago";

  // Flashlight mock simulation indicators
  bool _isFlashlightOn = false;
  Timer? _flashlightTimer;

  @override
  void initState() {
    super.initState();
    _startAlertEffects();
    _startCountdown();
    _calculateTimeElapsed();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAlertEffects() async {
    try {
      // Loop emergency alarm ringtone
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/emergency.mp3'));

      // Continuous emergency vibration pattern
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [600, 1000, 600, 1000],
          repeat: 0,
        );
      }
    } catch (_) {}

    // Simulated camera flashlight blink interval
    _flashlightTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _isFlashlightOn = !_isFlashlightOn;
        });
      }
    });
  }

  void _stopAlertEffects() async {
    try {
      await _audioPlayer.stop();
      Vibration.cancel();
      _flashlightTimer?.cancel();
    } catch (_) {}
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _handleTimeout();
      }
    });
  }

  void _calculateTimeElapsed() {
    try {
      final reqTime = DateTime.parse(widget.createdAt);
      final diff = DateTime.now().difference(reqTime);
      if (diff.inMinutes == 0) {
        _timeElapsed = "${diff.inSeconds}s ago";
      } else {
        _timeElapsed = "${diff.inMinutes}m ago";
      }
    } catch (_) {
      _timeElapsed = "Just now";
    }
  }

  void _handleTimeout() async {
    _stopAlertEffects();
    _countdownTimer?.cancel();

    // Log ignored report to Firestore delivery tracker
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.requestId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection("delivery_reports").add({
          "requestId": widget.requestId,
          "userId": user.uid,
          "status": "ignored",
          "timestamp": FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _acceptAlert() async {
    _stopAlertEffects();
    _countdownTimer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final timestamp = DateTime.now().toIso8601String();
      try {
        // 1. Log accept
        await FirebaseFirestore.instance.collection("accepted_requests").doc(widget.requestId).set({
          "userId": user.uid,
          "userName": user.email ?? "Responder",
          "acceptedAt": timestamp,
          "patientName": widget.patientName,
          "hospitalId": widget.hospitalId,
          "status": "responding"
        });

        // 2. Log response time metrics
        final reqTime = DateTime.parse(widget.createdAt);
        final reactionMillis = DateTime.now().difference(reqTime).inMilliseconds;

        await FirebaseFirestore.instance.collection("response_times").add({
          "requestId": widget.requestId,
          "userId": user.uid,
          "reactionMillis": reactionMillis,
          "acceptedAt": timestamp,
        });

        // 3. Update responder availability state in user profile
        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "availability": "Busy",
          "currentIncidentId": widget.requestId,
        });
      } catch (_) {}
    }

    // Launch Navigation directions
    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${widget.lat},${widget.lng}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are now responding. Routing active.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _declineAlert() async {
    _stopAlertEffects();
    _countdownTimer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.requestId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection("declined_requests").add({
          "requestId": widget.requestId,
          "userId": user.uid,
          "reason": "Decline button pressed by responder",
          "timestamp": FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _callPatient() async {
    final Uri url = Uri.parse("tel:${widget.phone}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  void dispose() {
    _stopAlertEffects();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Flashlight mockup blinking background effect integration
    final Color bgColor = _isFlashlightOn ? const Color(0xFF6E0D0D) : const Color(0xFF1E0707);

    return PopScope(
      canPop: false, // Prevent physical back buttons during incoming call
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, const Color(0xFF0C0707)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 30),

                // Alarm header & flashing icon
                Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.emergency_share_outlined, color: AppTheme.primary, size: 68),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "🚨 RAPID EMERGENCY CALL",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent.shade100,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${widget.bloodGroup} Needed Urgently",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "Triage Severity: ${widget.urgency}",
                      style: GoogleFonts.poppins(color: Colors.orange.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Call details box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.person_outline, "Patient", widget.patientName),
                        const Divider(color: Colors.white10, height: 16),
                        _infoRow(Icons.local_hospital_outlined, "Hospital", widget.location),
                        const Divider(color: Colors.white10, height: 16),
                        _infoRow(Icons.bloodtype_outlined, "Quantity Needed", "${widget.units} Units"),
                        const Divider(color: Colors.white10, height: 16),
                        _infoRow(Icons.map_outlined, "Transit distance", "${widget.distance} (${widget.eta} min ETA)"),
                        const Divider(color: Colors.white10, height: 16),
                        _infoRow(Icons.access_time_outlined, "Time Elapsed", _timeElapsed),
                      ],
                    ),
                  ),
                ),

                // Countdown clock & Action buttons
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / 60,
                            strokeWidth: 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        ),
                        Text(
                          "$_secondsRemaining s",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Calling actions accept/decline grid
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          
                          // Decline
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _declineAlert,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.call_end, color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("Decline", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),

                          // Call Patient
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _callPatient,
                                child: Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Icon(Icons.phone_in_talk, color: Colors.white70, size: 22),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("Call Seaker", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
                            ],
                          ),

                          // Accept
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _acceptAlert,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("Accept Call", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 12),
        Text(
          "$label:",
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}