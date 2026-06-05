import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

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

  final List<Map<String, dynamic>> _mockDonors = [
    {"name": "Amit Sharma", "distance": "0.8 km", "group": "A+", "angle": 0.8, "radius": 0.4, "show": false},
    {"name": "Priya Patel", "distance": "1.4 km", "group": "A+", "angle": 2.3, "radius": 0.6, "show": false},
    {"name": "Rohan Das", "distance": "2.1 km", "group": "A+", "angle": 4.1, "radius": 0.75, "show": false},
  ];

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

    // Trigger donor appearance step-by-step
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _mockDonors[0]["show"] = true);
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mockDonors[1]["show"] = true);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mockDonors[2]["show"] = true;
          _foundDonors = true;
        });
      }
    });
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

                        // Render Mock Donors on Polar Coordinates
                        ..._mockDonors.map((donor) {
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
                        ? "3 active donors are in range. Tap on any donor pulse to contact."
                        : "Broadcasting emergency signal to nearby A+ donors...",
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
                      onPressed: () {
                        Navigator.pop(context);
                        // Mock phone trigger
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
