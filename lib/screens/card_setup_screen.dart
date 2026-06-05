import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class CardSetupScreen extends StatefulWidget {
  const CardSetupScreen({super.key});

  @override
  State<CardSetupScreen> createState() => _CardSetupScreenState();
}

class _CardSetupScreenState extends State<CardSetupScreen> {
  final name = TextEditingController();
  final address = TextEditingController();
  final phone1 = TextEditingController();
  final phone2 = TextEditingController();

  String bloodGroup = "A+";
  bool loading = false;

  Future<void> saveCard() async {
    if (name.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        phone1.text.trim().isEmpty ||
        phone2.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all details", style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.charcoal,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "name": name.text.trim(),
        "address": address.text.trim(),
        "phone1": phone1.text.trim(),
        "phone2": phone2.text.trim(),
        "bloodGroup": bloodGroup,
        "hasCardData": true,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Emergency Card updated successfully", style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade800,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: $e", style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryDark,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Card Profile Setup",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔴 HEADER BANNER CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Setup Emergency Card",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "These details are embedded into your NFC card and QR code, accessible to first responders in an emergency.",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Personal Info",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // NAME INPUT
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  hintText: "Enter your legal name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // ADDRESS INPUT
              TextField(
                controller: address,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Home Address",
                  hintText: "Enter complete address",
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Emergency Contacts",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // CONTACT 1
              TextField(
                controller: phone1,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Emergency Contact 1",
                  hintText: "Contact phone number",
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // CONTACT 2
              TextField(
                controller: phone2,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Emergency Contact 2",
                  hintText: "Alternate contact number",
                  prefixIcon: Icon(Icons.phone_callback_outlined),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Medical Context",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // BLOOD GROUP DROPDOWN
              DropdownButtonFormField<String>(
                value: bloodGroup,
                decoration: const InputDecoration(
                  labelText: "Blood Group",
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => bloodGroup = val!),
              ),

              const SizedBox(height: 40),

              // 🔴 SAVE BUTTON
              GestureDetector(
                onTap: loading ? null : saveCard,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            "Save Card details",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
