import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      "name": name.text.trim(),
      "address": address.text.trim(),
      "phone1": phone1.text.trim(),
      "phone2": phone2.text.trim(),
      "bloodGroup": bloodGroup,
      "hasCardData": true,
    }, SetOptions(merge: true));

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      body: SafeArea(
        child: Column(
          children: [
            // 🔴 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                    "Setup Emergency Card",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Fill your emergency details",
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
                          _input(name, "Full Name", Icons.person),
                          _divider(),

                          _input(address, "Address", Icons.location_on),
                          _divider(),

                          _input(
                            phone1,
                            "Emergency Contact 1",
                            Icons.phone,
                            type: TextInputType.phone,
                          ),
                          _divider(),

                          _input(
                            phone2,
                            "Emergency Contact 2",
                            Icons.phone,
                            type: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _card(
                      child: DropdownButtonFormField(
                        value: bloodGroup,
                        decoration: _inputStyle("Blood Group"),
                        items:
                            ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => bloodGroup = val!),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔴 PREMIUM BUTTON
                    GestureDetector(
                      onTap: loading ? null : saveCard,
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
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Save Card",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
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
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.red),
        hintText: hint,
        border: InputBorder.none,
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(labelText: label, border: InputBorder.none);
  }

  Widget _divider() {
    return const Divider(height: 20, thickness: 0.5);
  }
}
