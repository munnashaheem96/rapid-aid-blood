import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class CameraGuidanceScreen extends StatefulWidget {
  const CameraGuidanceScreen({super.key});

  @override
  State<CameraGuidanceScreen> createState() => _CameraGuidanceScreenState();
}

class _CameraGuidanceScreenState extends State<CameraGuidanceScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isMockCamera = false;
  String _activeGuide = "CPR Posture";
  String _alignmentStatus = "✅ Alignment Correct (92% Match)";
  String _instructions = "Place the heel of one hand on the center of the patient's chest. Place your other hand on top, interlocking your fingers.";
  Color _statusColor = Colors.green;

  // Animation for simulated scan line
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        debugPrint("⚠️ Camera permission denied, switching to Mock scan simulator.");
        setState(() {
          _isMockCamera = true;
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("⚠️ No hardware camera detected, switching to Mock scan simulator.");
        setState(() {
          _isMockCamera = true;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e. Switching to mock simulator.");
      if (mounted) {
        setState(() {
          _isMockCamera = true;
        });
      }
    }
  }

  void _switchGuide(String guideName) {
    setState(() {
      _activeGuide = guideName;
      if (guideName == "CPR Posture") {
        _alignmentStatus = "✅ Alignment Correct (92% Match)";
        _statusColor = Colors.green;
        _instructions = "Place the heel of one hand on the center of the patient's chest. Place your other hand on top, interlocking your fingers.";
      } else if (guideName == "Tourniquet") {
        _alignmentStatus = "⚠️ Position Too Low (Apply 2 inches above wound)";
        _statusColor = Colors.orange;
        _instructions = "Apply tourniquet high and tight on the limb. Avoid placing directly over joints or bones.";
      } else if (guideName == "Heimlich") {
        _alignmentStatus = "❌ Obstruction Guide Not Positioned";
        _statusColor = Colors.red;
        _instructions = "Stand behind the choking patient. Place your fist slightly above their navel and pull in-and-up quickly.";
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "AI Camera Triage Guide",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 🎥 Viewport layer (Live or Mock simulation)
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null && !_isMockCamera
                ? CameraPreview(_cameraController!)
                : _buildMockCameraView(),
          ),

          // Viewfinder Custom Paint Guidelines
          Positioned.fill(
            child: CustomPaint(
              painter: CameraGuidePainter(activeGuide: _activeGuide),
            ),
          ),

          // Animated Scanning Laser overlay
          AnimatedBuilder(
            animation: _scannerAnimation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * _scannerAnimation.value,
                left: 20,
                right: 20,
                child: Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withOpacity(0.8),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          // Top selector chips
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _guideChip("CPR Posture"),
                  const SizedBox(width: 10),
                  _guideChip("Tourniquet"),
                  const SizedBox(width: 10),
                  _guideChip("Heimlich"),
                ],
              ),
            ),
          ),

          // Bottom feedback card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.charcoal.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "AI FEEDBACK ANALYSIS",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor),
                        ),
                        child: Text(
                          _alignmentStatus,
                          style: GoogleFonts.poppins(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _instructions,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.white24,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockCameraView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.transparent, Colors.black87],
          radius: 1.1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_outlined, color: Colors.white24, size: 54),
            const SizedBox(height: 12),
            Text(
              "Mock Triage Scanner Active",
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              "(Align overlay on patient target to begin)",
              style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideChip(String title) {
    bool isSelected = _activeGuide == title;
    return GestureDetector(
      onTap: () => _switchGuide(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white24,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white24),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraGuidePainter extends CustomPainter {
  final String activeGuide;

  CameraGuidePainter({required this.activeGuide});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw grid lines (telemetry viewfinder)
    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), dashPaint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), dashPaint);
    canvas.drawLine(Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33), dashPaint);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), dashPaint);

    if (activeGuide == "CPR Posture") {
      final center = Offset(size.width / 2, size.height * 0.42);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 140, height: 180),
        paint,
      );

      final targetPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 8, targetPaint);
    } else if (activeGuide == "Tourniquet") {
      final limbPaint = Paint()
        ..color = Colors.orange.withOpacity(0.6)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(size.width * 0.25, size.height * 0.2), Offset(size.width * 0.25, size.height * 0.7), limbPaint);
      canvas.drawLine(Offset(size.width * 0.75, size.height * 0.2), Offset(size.width * 0.75, size.height * 0.7), limbPaint);

      final linePaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(size.width * 0.25, size.height * 0.35), Offset(size.width * 0.75, size.height * 0.35), linePaint);
    } else if (activeGuide == "Heimlich") {
      final center = Offset(size.width / 2, size.height * 0.5);
      paint.color = Colors.red.withOpacity(0.6);
      canvas.drawCircle(center, 50, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
