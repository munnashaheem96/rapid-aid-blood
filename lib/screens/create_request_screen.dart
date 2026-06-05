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
  bool isFetchingLocation = false;

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
    setState(() {
      isFetchingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          location = "Location permission denied";
          isFetchingLocation = false;
        });
        return;
      }

      Position pos = await Geolocator.getCurrentPosition();

      lat = pos.latitude;
      lng = pos.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (!mounted) return;

      setState(() {
        location = "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
        isFetchingLocation = false;
      });
    } catch (e) {
      debugPrint("Location error: $e");
      if (mounted) {
        setState(() {
          location = "Failed to fetch GPS coordinates";
          isFetchingLocation = false;
        });
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (int.tryParse(unitsController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Units must be a valid number")),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // SOS Broadcast Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC62828).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Emergency Broadcast",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Bypasses Do-Not-Disturb alerts for matching donors within 15 km.",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.85),
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
                "Required Blood Group",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // 🩸 Circular blood group chip grid
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map((group) => _bloodGroupChip(group))
                    .toList(),
              ),

              const SizedBox(height: 28),

              Text(
                "Patient Details Form",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // 📝 Inputs
              _inputField(
                controller: nameController,
                label: "Patient Full Name",
                icon: Icons.person_outline,
              ),
              _inputField(
                controller: bystanderController,
                label: "Bystander / Contact Person Name",
                icon: Icons.assignment_ind_outlined,
              ),
              _inputField(
                controller: hospitalController,
                label: "Hospital Name, Branch & Room No.",
                icon: Icons.local_hospital_outlined,
              ),
              _inputField(
                controller: unitsController,
                label: "Required Blood Units (Qty)",
                icon: Icons.water_drop_outlined,
                type: TextInputType.number,
              ),
              _inputField(
                controller: phoneController,
                label: "Emergency Contact Phone Number",
                icon: Icons.phone_outlined,
                type: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              Text(
                "Urgency Level",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // ⚠️ Segmented Urgency Row
              Row(
                children: [
                  _urgencyChip("Normal", Colors.blue.shade600),
                  const SizedBox(width: 8),
                  _urgencyChip("Urgent", Colors.orange.shade700),
                  const SizedBox(width: 8),
                  _urgencyChip("Critical", Colors.red.shade700),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                "Additional Instructions (Optional)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textMain.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),

              // Notes Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "E.g. Enter through Gate No. 3, contact relative at arrival...",
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textSecondary.withOpacity(0.5),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Location card display with refresher
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Request Location",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            location,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textMain,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFetchingLocation)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20),
                        onPressed: getLocation,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // SOS Pulsing Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  label: Text(
                    "BROADCAST SOS ALERT",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: createRequest,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 🩸 Blood Group Custom Selector Chip
  Widget _bloodGroupChip(String group) {
    bool isSelected = bloodGroup == group;
    return GestureDetector(
      onTap: () => setState(() => bloodGroup = group),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Center(
          child: Text(
            group,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : AppTheme.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  /// ⚠️ Urgency Level Custom Selector Chip
  Widget _urgencyChip(String level, Color color) {
    bool isSelected = urgency == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => urgency = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Center(
            child: Text(
              level,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✏️ Input text fields styled container
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMain),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: AppTheme.textSecondary.withOpacity(0.7),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.7), size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
