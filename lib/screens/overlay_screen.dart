import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:url_launcher/url_launcher.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen>
    with SingleTickerProviderStateMixin {
  String bloodGroup = "Loading...";
  String location = "Fetching...";
  String phone = "";

  late AnimationController _controller;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    sub = FlutterOverlayWindow.overlayListener.listen((event) {
      setState(() {
        bloodGroup = event["bloodGroup"];
        location = event["location"];
        phone = event["phone"];
      });
    });
  }

  Future<void> makeCall() async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB71C1C), Color(0xFF7F0000)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _controller,
                child: const Icon(Icons.warning,
                    color: Colors.white, size: 60),
              ),

              const SizedBox(height: 10),

              const Text("EMERGENCY ALERT",
                  style: TextStyle(color: Colors.white)),

              const SizedBox(height: 10),

              Text("$bloodGroup BLOOD REQUIRED",
                  style: const TextStyle(color: Colors.white)),

              const SizedBox(height: 8),

              Text(location,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),

              const SizedBox(height: 10),

              Text("📞 $phone",
                  style: const TextStyle(color: Colors.white)),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FlutterOverlayWindow.closeOverlay();
                      },
                      child: const Text("DECLINE"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await makeCall();
                        await FlutterOverlayWindow.closeOverlay();
                      },
                      child: const Text("CALL"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}