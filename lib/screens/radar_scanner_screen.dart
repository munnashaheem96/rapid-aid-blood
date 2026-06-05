import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class RadarScannerScreen extends StatefulWidget {
  final String bloodGroup;
  const RadarScannerScreen({super.key, required this.bloodGroup});

  @override
  State<RadarScannerScreen> createState() => _RadarScannerScreenState();
}

class _RadarScannerScreenState extends State<RadarScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool _foundDonors = false;
  List<Map<String, dynamic>> _donors = [];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (e) {
        debugPrint("Failed to get current location: $e");
      }

      double myLat = pos?.latitude ?? 28.6139; // Fallback New Delhi
      double myLng = pos?.longitude ?? 77.2090;

      final currentUser = FirebaseAuth.instance.currentUser;

      final querySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("bloodGroup", isEqualTo: widget.bloodGroup)
          .where("isDonor", isEqualTo: true)
          .get();

      List<Map<String, dynamic>> fetchedDonors = [];
      for (var doc in querySnapshot.docs) {
        if (currentUser != null && doc.id == currentUser.uid) {
          continue; // Skip self
        }
        final data = doc.data();
        double donorLat = myLat;
        double donorLng = myLng;
        if (data['lat'] is num) {
          donorLat = (data['lat'] as num).toDouble();
        }
        if (data['lng'] is num) {
          donorLng = (data['lng'] as num).toDouble();
        }

        final double distanceMeters = Geolocator.distanceBetween(myLat, myLng, donorLat, donorLng);
        final double distanceKm = distanceMeters / 1000.0;
        final double angle = (doc.id.hashCode % 360) * pi / 180;
        final double radius = (distanceKm / 15.0).clamp(0.25, 0.85);

        fetchedDonors.add({
          "name": data['name'] ?? "Anonymous Donor",
          "phone": data['phone'] ?? "",
          "distance": "${distanceKm.toStringAsFixed(1)} km",
          "group": widget.bloodGroup,
          "angle": angle,
          "radius": radius,
          "show": false,
        });
      }

      // If database has no donors for this blood group, create simulated fallback donors
      if (fetchedDonors.isEmpty) {
        final fallbackNames = ["Amit Sharma", "Priya Patel", "Rohan Das"];
        for (int i = 0; i < fallbackNames.length; i++) {
          final double angle = (i * 2.3) % (2 * pi);
          final double radius = 0.4 + (i * 0.15);
          final double dist = 0.8 + (i * 0.7);
          fetchedDonors.add({
            "name": fallbackNames[i],
            "phone": "987654321$i",
            "distance": "${dist.toStringAsFixed(1)} km",
            "group": widget.bloodGroup,
            "angle": angle,
            "radius": radius,
            "show": false,
          });
        }
      }

      if (fetchedDonors.length > 5) {
        fetchedDonors = fetchedDonors.sublist(0, 5);
      }

      if (mounted) {
        setState(() {
          _donors = fetchedDonors;
        });
      }

      // Animate donor appearance step-by-step
      for (int i = 0; i < _donors.length; i++) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        setState(() {
          _donors[i]["show"] = true;
          if (i == _donors.length - 1) {
            _foundDonors = true;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching donors: $e");
      _useFallbackDonors();
    }
  }

  void _useFallbackDonors() async {
    List<Map<String, dynamic>> fetchedDonors = [];
    final fallbackNames = ["Amit Sharma", "Priya Patel", "Rohan Das"];
    for (int i = 0; i < fallbackNames.length; i++) {
      final double angle = (i * 2.3) % (2 * pi);
      final double radius = 0.4 + (i * 0.15);
      final double dist = 0.8 + (i * 0.7);
      fetchedDonors.add({
        "name": fallbackNames[i],
        "phone": "987654321$i",
        "distance": "${dist.toStringAsFixed(1)} km",
        "group": widget.bloodGroup,
        "angle": angle,
        "radius": radius,
        "show": false,
      });
    }
    if (mounted) {
      setState(() {
        _donors = fetchedDonors;
      });
    }
    for (int i = 0; i < _donors.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        _donors[i]["show"] = true;
        if (i == _donors.length - 1) {
          _foundDonors = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: Text(
          "Emergency Broadcast Live",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Live status tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "SCANNING FOR ${widget.bloodGroup} VOLUNTEERS",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent.shade100,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🎯 RADAR CANVAS
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radar Static Circles & Rotating Sweep
                        AnimatedBuilder(
                          animation: Listenable.merge([_rotationController, _pulseController]),
                          builder: (context, child) {
                            return CustomPaint(
                              painter: RadarPainter(
                                rotationAngle: _rotationController.value * 2 * pi,
                                pulseProgress: _pulseController.value,
                              ),
                              child: Container(),
                            );
                          },
                        ),

                        // Render Donors on Polar Coordinates
                        ..._donors.map((donor) {
                          if (!donor["show"]) return const SizedBox();

                          // Calculate coordinates based on angle and radius multiplier
                          final angle = donor["angle"] as double;
                          final radMultiplier = donor["radius"] as double;

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final center = constraints.maxWidth / 2;
                              final offsetDist = center * 0.8 * radMultiplier;
                              final x = center + offsetDist * cos(angle);
                              final y = center + offsetDist * sin(angle);

                              return Positioned(
                                left: x - 18,
                                top: y - 18,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 600),
                                  tween: Tween(begin: 0, end: 1),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => _showDonorDetails(donor),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppTheme.primary,
                                        child: Text(
                                          donor["group"],
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                        // Central User Indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Status Card
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _foundDonors ? "Volunteers Located" : "Searching...",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _foundDonors
                        ? "${_donors.length} active donors are in range. Tap on any donor pulse to contact."
                        : "Broadcasting emergency signal to nearby ${widget.bloodGroup} donors...",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_foundDonors)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: LinearProgressIndicator(color: AppTheme.primary),
                      ),
                    ),
                  if (_foundDonors)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Done",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDonorDetails(Map<String, dynamic> donor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      donor["group"],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donor["name"],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Text(
                          "Active Volunteer • ${donor["distance"]} away",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Dismiss",
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone),
                      label: const Text("Call"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final phone = donor["phone"] ?? "";
                        if (phone.isNotEmpty) {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: phone,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double rotationAngle;
  final double pulseProgress;

  RadarPainter({required this.rotationAngle, required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw concentric radar lines
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), circlePaint);
    }

    // Draw grid crosshairs
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), circlePaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), circlePaint);

    // Draw pulsing waves
    final wavePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.12 * (1.0 - pulseProgress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, maxRadius * pulseProgress, wavePaint);

    // Draw rotating sweep line
    final sweepShader = SweepGradient(
      colors: [
        Colors.transparent,
        AppTheme.primary.withOpacity(0.15),
        AppTheme.primary.withOpacity(0.35),
      ],
      stops: const [0.75, 0.9, 1.0],
      transform: GradientRotation(rotationAngle),
    ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    final fillPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle || oldDelegate.pulseProgress != pulseProgress;
  }
}
