import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rapid_aid/screens/card_setup_screen.dart';
import 'package:rapid_aid/screens/checkout_screen.dart';

class EmergencyCardScreen extends StatelessWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),

            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;

              // 🚨 FIRST TIME → OPEN SETUP
              if (data == null || data['hasCardData'] != true) {
                Future.microtask(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CardSetupScreen()),
                  );
                });
                return const SizedBox();
              }

              final name = data['name'] ?? "";
              final address = data['address'] ?? "";
              final phone = "${data['phone1']}\n${data['phone2']}";
              final blood = data['bloodGroup'] ?? "";

              // 🔥 QR DATA
              final qrData = jsonEncode({
                "name": name,
                "address": address,
                "phone1": data['phone1'],
                "phone2": data['phone2'],
                "bloodGroup": blood,
              });

              return Column(
                children: [
                  const SizedBox(height: 20),

                  // 🪪 CARD
                  AspectRatio(
                    aspectRatio: 1050 / 600,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;

                            return Stack(
                              children: [
                                // 🔥 BACKGROUND
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/images/virtual_card.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                // 🔥 TEXT (NO LABELS)
                                Positioned(
                                  left: w * 0.46,
                                  top: h * 0.22,
                                  child: SizedBox(
                                    width: w * 0.45,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 👤 NAME
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: h * 0.07,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 6,
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: h * 0.11),

                                        // 📍 ADDRESS
                                        Text(
                                          address,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: h * 0.05,
                                          ),
                                        ),

                                        SizedBox(height: h * 0.12),

                                        // 📞 PHONE
                                        Text(
                                          phone,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: h * 0.055,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 🔥 QR CODE
                                Positioned(
                                  left: w * 0.11,
                                  bottom: h * 0.10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: QrImageView(
                                      data: qrData,
                                      size: w * 0.23,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),

                                // 🔥 BLOOD GROUP WATERMARK
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Text(
                                    blood,
                                    style: TextStyle(
                                      fontSize: h * 0.45,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Your Emergency Card",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Scan QR to get full emergency details",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // 🔥 ORDER BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Order Physical NFC Card",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
