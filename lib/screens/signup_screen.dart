import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rapid_aid/screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  /// Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final bloodGroupController = TextEditingController();

  /// JSON DATA
  Map<String, dynamic> locationData = {};
  List<String> states = [];
  List<String> districts = [];

  String? selectedState;
  String? selectedDistrict;

  /// Manual input
  bool manualLocation = false;
  final manualStateController = TextEditingController();
  final manualDistrictController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.requestPermission();
    loadLocationData();
  }

  /// 🔥 LOAD JSON
  Future<void> loadLocationData() async {
    final response =
        await rootBundle.loadString('assets/india_locations.json');

    final data = jsonDecode(response);

    setState(() {
      locationData = data;
      states = data.keys.toList();
    });
  }

  /// 📍 LOCATION + FCM
  Future<Map<String, dynamic>> getUserMeta() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    Position pos = await Geolocator.getCurrentPosition();
    String? token = await FirebaseMessaging.instance.getToken();

    return {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'fcmToken': token
    };
  }

  /// 🚀 SIGNUP
  Future<void> signup() async {
    String state;
    String district;

    /// VALIDATION
    if (manualLocation) {
      state = manualStateController.text.trim();
      district = manualDistrictController.text.trim();

      if (state.isEmpty || district.isEmpty) {
        showSnack("Enter location manually");
        return;
      }
    } else {
      if (selectedState == null || selectedDistrict == null) {
        showSnack("Select state and district");
        return;
      }
      state = selectedState!;
      district = selectedDistrict!;
    }

    setState(() => isLoading = true);

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      var meta = await getUserMeta();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user!.uid)
          .set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "bloodGroup": bloodGroupController.text,

        /// LOCATION
        "state": state,
        "district": district,
        "lat": meta['lat'],
        "lng": meta['lng'],

        "fcmToken": meta['fcmToken'],

        "isDonor": true,
        "isAvailable": false,

        "createdAt": Timestamp.now(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showSnack(e.toString());
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: input("Full Name", Icons.person),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: emailController,
                          decoration: input("Email", Icons.email),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: phoneController,
                          decoration: input("Phone", Icons.phone),
                        ),
                        const SizedBox(height: 15),

                        /// BLOOD GROUP
                        DropdownButtonFormField<String>(
                          decoration:
                              input("Blood Group", Icons.bloodtype),
                          items: [
                            'A+','A-','B+','B-','O+','O-','AB+','AB-'
                          ].map((bg) {
                            return DropdownMenuItem(
                                value: bg, child: Text(bg));
                          }).toList(),
                          onChanged: (val) =>
                              bloodGroupController.text = val!,
                        ),

                        const SizedBox(height: 15),

                        /// MANUAL TOGGLE
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Enter manually"),
                            Switch(
                              value: manualLocation,
                              onChanged: (val) =>
                                  setState(() => manualLocation = val),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// LOCATION UI
                        if (!manualLocation) ...[
                          DropdownButtonFormField<String>(
                            value: selectedState,
                            hint: const Text("Select State"),
                            items: states.map((s) {
                              return DropdownMenuItem(
                                  value: s, child: Text(s));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedState = val;
                                districts = List<String>.from(
                                    locationData[val]);
                                selectedDistrict = null;
                              });
                            },
                            decoration: input("State", Icons.map),
                          ),
                          const SizedBox(height: 15),

                          DropdownButtonFormField<String>(
                            value: selectedDistrict,
                            hint: const Text("Select District"),
                            items: districts.map((d) {
                              return DropdownMenuItem(
                                  value: d, child: Text(d));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedDistrict = val),
                            decoration:
                                input("District", Icons.location_city),
                          ),
                        ] else ...[
                          TextField(
                            controller: manualStateController,
                            decoration:
                                input("Enter State", Icons.map),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: manualDistrictController,
                            decoration: input(
                                "Enter District", Icons.location_city),
                          ),
                        ],

                        const SizedBox(height: 25),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize:
                                const Size(double.infinity, 50),
                          ),
                          onPressed: isLoading ? null : signup,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("SIGN UP",
                                  style:
                                      TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration input(String text, IconData icon) {
    return InputDecoration(
      labelText: text,
      prefixIcon: Icon(icon, color: Colors.red),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}