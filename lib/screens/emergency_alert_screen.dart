import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final String bloodGroup;
  final String location;
  final String phone;

  const EmergencyAlertScreen({
    super.key,
    required this.bloodGroup,
    required this.location,
    required this.phone,
  });

  @override
  State<EmergencyAlertScreen> createState() =>
      _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    startAlert();
  }

  /// 🔊 Start sound + vibration
  void startAlert() async {
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sounds/emergency.mp3'));

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [500, 1000, 500, 1000],
          repeat: 0,
        );
      }
    } catch (e) {
      debugPrint("Error starting alert: $e");
    }
  }

  /// 🛑 Stop everything
  void stopAlert() async {
    await player.stop();
    Vibration.cancel();
  }

  /// 📞 Call
  Future<void> makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  void dispose() {
    stopAlert();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🔒 Disable back
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              /// 🔥 TOP TEXT
              Column(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 100),

                  const SizedBox(height: 20),

                  const Text(
                    "EMERGENCY ALERT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "${widget.bloodGroup} BLOOD REQUIRED",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.location,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "📞 ${widget.phone}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              /// 🔥 BUTTONS (CALL STYLE)
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /// ❌ DECLINE
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            stopAlert();
                            Navigator.pop(context);
                          },
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.call_end,
                                color: Colors.red, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Decline",
                            style: TextStyle(color: Colors.white))
                      ],
                    ),

                    /// 📞 CALL
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            stopAlert();
                            makeCall(widget.phone);
                          },
                          child: const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.call,
                                color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Call",
                            style: TextStyle(color: Colors.white))
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}