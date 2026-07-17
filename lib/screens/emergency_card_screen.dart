import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'package:rapid_aid/screens/card_setup_screen.dart';
import 'package:rapid_aid/screens/checkout_screen.dart';

class EmergencyCardScreen extends StatelessWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: const Text("Emergency Card"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
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
              final qrData =
                  "https://munnashaheem96.github.io/rapid-aid-card/user.html?id=$uid";

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 🪪 VIRTUAL CARD PREVIEW
                    AspectRatio(
                      aspectRatio: 1050 / 600,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
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

                                  // 🔥 CARD OVERLAY SHADING FOR TEXT READABILITY
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.4),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
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
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: h * 0.07,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 6,
                                                  color: Colors.black.withOpacity(0.5),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: h * 0.11),

                                          // 📍 ADDRESS
                                          Text(
                                            address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: h * 0.05,
                                              height: 1.2,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),

                                          SizedBox(height: h * 0.10),

                                          // 📞 PHONE
                                          Text(
                                            phone,
                                            style: GoogleFonts.poppins(
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

                                  // 🔥 QR CODE WITH GLOW AND CONTAINER
                                  Positioned(
                                    left: w * 0.11,
                                    bottom: h * 0.10,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.2),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: qrData,
                                        size: w * 0.23,
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),

                                  // 🔥 BLOOD GROUP WATERMARK
                                  Positioned(
                                    right: 15,
                                    bottom: 5,
                                    child: Text(
                                      blood,
                                      style: GoogleFonts.poppins(
                                        fontSize: h * 0.45,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.18),
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

                    const SizedBox(height: 32),

                    // CARD HEADLINE
                    Text(
                      "Your Emergency NFC Card",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Scan the QR code or tap the physical NFC card to instantly display your medical profile in an emergency.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🔥 ORDER CARD BLOCK
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.nfc_outlined,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Physical NFC Card",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.textMain,
                                      ),
                                    ),
                                    Text(
                                      "Waterproof, durable medical ID",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "₹140",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                                gradient: AppTheme.blueGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D47A1).withOpacity(0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Order Physical Emergency Card",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
