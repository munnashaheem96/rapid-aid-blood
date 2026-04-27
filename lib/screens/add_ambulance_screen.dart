import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AddAmbulanceScreen extends StatefulWidget {
  const AddAmbulanceScreen({super.key});

  @override
  State<AddAmbulanceScreen> createState() => _AddAmbulanceScreenState();
}

class _AddAmbulanceScreenState extends State<AddAmbulanceScreen> {
  final vehicle = TextEditingController();
  final driver = TextEditingController();
  final phone = TextEditingController();
  final org = TextEditingController();

  bool loading = false;

  Future<void> save() async {
    if (vehicle.text.isEmpty ||
        driver.text.isEmpty ||
        phone.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all details correctly")),
      );
      return;
    }

    setState(() => loading = true);

    final pos = await Geolocator.getCurrentPosition();

    await FirebaseFirestore.instance.collection('ambulances').add({
      "vehicleNo": vehicle.text.trim(),
      "driverName": driver.text.trim(),
      "phone": phone.text.trim(),
      "organization": org.text.trim(),
      "location": GeoPoint(pos.latitude, pos.longitude),
      "createdAt": Timestamp.now(),
    });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      body: SafeArea(
        child: Column(
          children: [
            // 🔴 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Ambulance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Register nearby emergency vehicle",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 🔥 FORM
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _card(
                      child: Column(
                        children: [
                          _input(
                            vehicle,
                            "Vehicle Number",
                            Icons.directions_car,
                          ),
                          _divider(),

                          _input(driver, "Driver Name", Icons.person),
                          _divider(),

                          _input(
                            phone,
                            "Phone",
                            Icons.phone,
                            type: TextInputType.phone,
                          ),
                          _divider(),

                          _input(org, "Organization", Icons.local_hospital),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 🔥 SAVE BUTTON (BOTTOM FIXED)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: loading ? null : save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save Ambulance",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 CARD CONTAINER
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: child,
    );
  }

  // 🔥 INPUT FIELD
  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.red),
        hintText: hint,
        border: InputBorder.none,
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 20);
  }
}
