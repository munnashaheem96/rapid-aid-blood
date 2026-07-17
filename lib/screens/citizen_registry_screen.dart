import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class CitizenRegistryScreen extends StatefulWidget {
  const CitizenRegistryScreen({super.key});

  @override
  State<CitizenRegistryScreen> createState() => _CitizenRegistryScreenState();
}

class _CitizenRegistryScreenState extends State<CitizenRegistryScreen> {
  String _selectedRole = "CPR Volunteer";
  bool _isLoading = false;
  bool _isRegistered = false;

  final List<Map<String, dynamic>> _roles = [
    {"name": "Doctor", "icon": Icons.medical_services_outlined, "desc": "Licensed medical practitioners for on-site triage"},
    {"name": "Nurse", "icon": Icons.local_hospital_outlined, "desc": "Nursing staff capable of trauma and wound management"},
    {"name": "CPR Volunteer", "icon": Icons.heart_broken_outlined, "desc": "Bystanders certified in cardiopulmonary resuscitation"},
    {"name": "Ambulance Driver", "icon": Icons.local_shipping_outlined, "desc": "Certified responders trained in ambulance evacuation"},
    {"name": "Pharmacist", "icon": Icons.local_pharmacy_outlined, "desc": "Local medical shop keepers with direct store supply access"},
    {"name": "Civil Defence", "icon": Icons.shield_outlined, "desc": "State volunteers trained in disaster relief"},
  ];

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (doc.exists && doc.data()?['isResponder'] == true) {
        setState(() {
          _isRegistered = true;
          _selectedRole = doc.data()?['role'] ?? "CPR Volunteer";
        });
      }
    } catch (_) {}
  }

  Future<void> _registerAsResponder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "isResponder": true,
        "role": _selectedRole,
        "reputationPoints": 150, // Initial bonus points
        "isActive": true
      });

      setState(() {
        _isRegistered = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully registered as a Citizen Responder!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update responder profile: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Citizen Responder Network",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.supervised_user_circle, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Join the First Line of Defence",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Intelligently receive alerts only when your specific skill matching profile is needed nearby.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Select Responder Category Role",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  final isSelected = _selectedRole == role['name'];

                  return GestureDetector(
                    onTap: _isRegistered ? null : () => setState(() => _selectedRole = role['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.grey.shade100,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
                            : AppTheme.premiumShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryLight : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              role['icon'],
                              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role['name'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role['desc'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              if (_isRegistered)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "You are actively registered in the Network as a $_selectedRole. Standing by for local incidents.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isLoading ? null : _registerAsResponder,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SUBMIT REGISTRATION",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
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
