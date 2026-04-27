import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:rapid_aid/main.dart';
import 'package:rapid_aid/screens/emergency_alert_screen.dart';

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
        }),
      );
    } catch (e) {
      debugPrint("Backend error: $e");
    }
  }

  /// 🔥 CREATE REQUEST (FIXED)
  Future createRequest() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        unitsController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return;
    }

    if (int.tryParse(unitsController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Units must be number")));
      return;
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;

    /// 🔥 SAVE DATA BEFORE CLEAR
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

    /// ✅ SAFETY CHECK
    if (!mounted) return;

    /// ✅ SHOW SUCCESS BEFORE POP
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Request sent successfully")));

    /// 🔥 CLEAR FIELDS
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

    /// 🔙 CLOSE SCREEN
    Navigator.pop(context);

    /// 🚨 NAVIGATE SAFELY USING GLOBAL KEY
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
      backgroundColor: const Color(0xFFF4F6FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Request",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              const Text(
                "Fill details to request blood instantly",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              /// 🩸 BLOOD GROUP
              const Text(
                "Blood Group",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map(
                      (e) => ChoiceChip(
                        label: Text(e),
                        selected: bloodGroup == e,
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                          color: bloodGroup == e ? Colors.white : Colors.black,
                        ),
                        onSelected: (_) => setState(() => bloodGroup = e),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 20),

              /// 📦 FORM
              _sectionCard(
                child: Column(
                  children: [
                    _input(nameController, "Patient Name", Icons.person),
                    _input(bystanderController, "Bystander", Icons.group),
                    _input(
                      hospitalController,
                      "Hospital",
                      Icons.local_hospital,
                    ),
                    _input(
                      unitsController,
                      "Units",
                      Icons.bloodtype,
                      type: TextInputType.number,
                    ),
                    _input(
                      phoneController,
                      "Phone",
                      Icons.phone,
                      type: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ⚠️ URGENCY
              const Text(
                "Urgency",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _sectionCard(
                child: DropdownButtonFormField<String>(
                  value: urgency,
                  items: ["Normal", "Urgent", "Critical"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => urgency = val ?? "Normal"),
                  decoration: _decoration("Select urgency"),
                ),
              ),

              const SizedBox(height: 20),

              /// 📝 NOTES
              const Text(
                "Notes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _sectionCard(
                child: TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: _decoration("Additional notes"),
                ),
              ),

              const SizedBox(height: 20),

              /// 📍 LOCATION
              _sectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// 🚀 BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: createRequest,
                  child: const Text(
                    "SUBMIT REQUEST",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  /// 🔧 UI HELPERS

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: _decoration(
          hint,
        ).copyWith(prefixIcon: Icon(icon, color: Colors.red)),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
