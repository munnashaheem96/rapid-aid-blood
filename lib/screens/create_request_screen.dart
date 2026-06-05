import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/main.dart';
import 'package:rapid_aid/screens/emergency_alert_screen.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String bloodGroup = "A+";
  String urgency = "Urgent";

  String location = "Fetching location...";
  double lat = 0;
  double lng = 0;

  final nameController = TextEditingController();
  final hospitalController = TextEditingController();
  final unitsController = TextEditingController();
  final phoneController = TextEditingController();
  final bystanderController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  /// 📍 LOCATION
  Future getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition();

      lat = pos.latitude;
      lng = pos.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (!mounted) return;

      setState(() {
        location =
            "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  /// 🚨 BACKEND
  Future sendAlertToBackend() async {
    try {
      await http.post(
        Uri.parse("https://rapid-aid-backend.onrender.com/send-alert"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bloodGroup": bloodGroup,
          "location": location,
          "lat": lat,
          "lng": lng,
          "phone": phoneController.text,
        }),
      );
    } catch (e) {
      debugPrint("Backend error: $e");
    }
  }

  /// 🔥 CREATE REQUEST
  Future createRequest() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        unitsController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    if (int.tryParse(unitsController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Units must be a valid number")));
      return;
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;

    final savedPhone = phoneController.text;
    final savedBlood = bloodGroup;

    await FirebaseFirestore.instance.collection('blood_requests').add({
      'uid': uid,
      'name': nameController.text,
      'bystander': bystanderController.text,
      'bloodGroup': bloodGroup,
      'units': int.parse(unitsController.text),
      'hospital': hospitalController.text,
      'phone': phoneController.text,
      'notes': notesController.text,
      'urgency': urgency,
      'location': location,
      'lat': lat,
      'lng': lng,
      'createdAt': Timestamp.now(),
    });

    await sendAlertToBackend();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text("Request sent successfully", style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.charcoal,
      ),
    );

    nameController.clear();
    bystanderController.clear();
    hospitalController.clear();
    unitsController.clear();
    phoneController.clear();
    notesController.clear();

    setState(() {
      bloodGroup = "A+";
      urgency = "Urgent";
    });

    Navigator.pop(context);

    Future.delayed(const Duration(milliseconds: 300), () {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EmergencyAlertScreen(
            bloodGroup: savedBlood,
            location: location,
            phone: savedPhone,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: const Text("Create Request"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Blood Requirement Form",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              Text(
                "Fill details to request blood instantly in your area",
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
              ),

              const SizedBox(height: 24),

              /// 🩸 BLOOD GROUP SELECTOR
              Text(
                "Select Required Blood Group",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map(
                      (e) {
                        bool isSelected = bloodGroup == e;
                        return GestureDetector(
                          onTap: () => setState(() => bloodGroup = e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                              boxShadow: AppTheme.premiumShadow,
                            ),
                            child: Text(
                              e,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : AppTheme.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    .toList(),
              ),

              const SizedBox(height: 24),

              /// 📦 FORM
              _sectionCard(
                child: Column(
                  children: [
                    _input(nameController, "Patient Name", Icons.person_outline),
                    _input(bystanderController, "Bystander / Relative Name", Icons.group_outlined),
                    _input(
                      hospitalController,
                      "Hospital Name & Branch",
                      Icons.local_hospital_outlined,
                    ),
                    _input(
                      unitsController,
                      "Required Units (Quantity)",
                      Icons.bloodtype_outlined,
                      type: TextInputType.number,
                    ),
                    _input(
                      phoneController,
                      "Contact Phone Number",
                      Icons.phone_outlined,
                      type: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ⚠️ URGENCY
              Text(
                "Urgency Level",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 8),

              _sectionCard(
                child: DropdownButtonFormField<String>(
                  value: urgency,
                  items: ["Normal", "Urgent", "Critical"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins())))
                      .toList(),
                  onChanged: (val) => setState(() => urgency = val ?? "Normal"),
                  decoration: const InputDecoration(
                    labelText: "Urgency Status",
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 📝 NOTES
              Text(
                "Additional Instructions (Optional)",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 8),

              _sectionCard(
                child: TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "E.g. Call before visiting, specific entry gates...",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 📍 LOCATION DISPLAY
              _sectionCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Request Location",
                            style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            location,
                            style: GoogleFonts.poppins(color: AppTheme.textMain, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /// 🚀 SUBMIT REQUEST BUTTON
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: createRequest,
                  child: Text(
                    "SUBMIT EMERGENCY REQUEST",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
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

  /// 🔧 UI HELPERS
  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: child,
    );
  }

  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

