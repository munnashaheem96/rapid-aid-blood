import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';

class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId = "";
  bool otpSent = false;
  bool loading = false;

  int seconds = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadPhone();
  }

  // 🔥 FETCH PHONE
  Future<void> loadPhone() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    phoneController.text = doc.data()?['phone'] ?? "";
  }

  // 🔥 TIMER
  void startTimer() {
    seconds = 30;
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  // 🔥 SEND OTP
  Future sendOTP() async {
    setState(() => loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${phoneController.text}",

      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      },

      verificationFailed: (e) {
        setState(() => loading = false);
        _showError(e.message ?? "Error");
      },

      codeSent: (verId, _) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          loading = false;
        });

        startTimer();
      },

      codeAutoRetrievalTimeout: (verId) {
        verificationId = verId;
      },
    );
  }

  // 🔥 VERIFY OTP
  Future verifyOTP(String code) async {
    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        "phoneVerified": true,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Phone Verified")));

      Navigator.pop(context);
    } catch (e) {
      _showError("Invalid OTP");
    }

    setState(() => loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 🔥 TITLE
              const Text(
                "Verify Phone",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                "OTP sent to +91 ${phoneController.text}",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 🔢 OTP BOXES
              if (otpSent)
                Pinput(
                  length: 6,
                  controller: otpController,
                  onCompleted: verifyOTP,
                  defaultPinTheme: PinTheme(
                    width: 50,
                    height: 60,
                    textStyle: const TextStyle(fontSize: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // 🔁 RESEND
              if (otpSent)
                Center(
                  child: TextButton(
                    onPressed: seconds == 0 ? sendOTP : null,
                    child: Text(
                      seconds == 0 ? "Resend OTP" : "Resend in $seconds s",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),

              const Spacer(),

              // 🔥 BUTTON
              if (!otpSent)
                GestureDetector(
                  onTap: loading ? null : sendOTP,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                      ),
                    ),
                    child: Center(
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Send OTP",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
