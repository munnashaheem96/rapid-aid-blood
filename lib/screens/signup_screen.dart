import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/screens/home_screen.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final bloodGroupController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  Map<String, dynamic> locationData = {};
  List<String> states = [];
  List<String> districts = [];

  String? selectedState;
  String? selectedDistrict;

  @override
  void initState() {
    super.initState();
    loadLocationData();
  }

  /// 📍 Load State/District JSON
  Future<void> loadLocationData() async {
    try {
      final response = await rootBundle.loadString('assets/india_locations.json');
      final data = jsonDecode(response);

      setState(() {
        locationData = data;
        states = data.keys.toList();
      });
    } catch (e) {
      debugPrint("Error loading location json: $e");
    }
  }

  /// 📍 Get Location + Token
  Future<Map<String, dynamic>> getMeta() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    Position pos = await Geolocator.getCurrentPosition();
    String? token = await FirebaseMessaging.instance.getToken();

    return {
      "lat": pos.latitude,
      "lng": pos.longitude,
      "fcmToken": token
    };
  }

  /// 🔐 SIGNUP
  Future<void> signup() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        bloodGroupController.text.isEmpty) {
      showSnack("Please fill all fields");
      return;
    }

    if (passwordController.text.length < 6) {
      showSnack("Password must be at least 6 characters");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showSnack("Passwords do not match");
      return;
    }

    if (selectedState == null || selectedDistrict == null) {
      showSnack("Please select your state and district");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      var meta = await getMeta();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.user!.uid)
          .set({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "bloodGroup": bloodGroupController.text,

        "state": selectedState,
        "district": selectedDistrict,

        "lat": meta["lat"],
        "lng": meta["lng"],
        "fcmToken": meta["fcmToken"],

        "isDonor": true,
        "createdAt": Timestamp.now(),
      });

      showSnack("Account created successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.darkGradient,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      "Create Account",
                      textAlign: CenterTheme.alignment,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Register as a volunteer/donor in seconds",
                      textAlign: CenterTheme.alignment,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),

                    /// FORM CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          input(nameController, "Full Name", Icons.person_outline),
                          input(emailController, "Email Address", Icons.email_outlined),
                          input(phoneController, "Phone Number", Icons.phone_outlined, type: TextInputType.phone),

                          /// BLOOD GROUP DROPDOWN
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Blood Group",
                              prefixIcon: Icon(Icons.bloodtype_outlined),
                            ),
                            items: [
                              'A+','A-','B+','B-','O+','O-','AB+','AB-'
                            ].map((e) {
                              return DropdownMenuItem(
                                  value: e, child: Text(e, style: GoogleFonts.poppins()));
                            }).toList(),
                            onChanged: (val) => bloodGroupController.text = val!,
                          ),

                          const SizedBox(height: 16),

                          /// PASSWORD
                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// CONFIRM PASSWORD
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !showPassword,
                            decoration: const InputDecoration(
                              labelText: "Confirm Password",
                              prefixIcon: Icon(Icons.lock_clock_outlined),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// STATE DROPDOWN
                          DropdownButtonFormField<String>(
                            value: selectedState,
                            hint: Text("Select State", style: GoogleFonts.poppins(fontSize: 14)),
                            items: states.map((s) {
                              return DropdownMenuItem(
                                  value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedState = val;
                                districts =
                                    List<String>.from(locationData[val]);
                                selectedDistrict = null;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: "State",
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// DISTRICT DROPDOWN
                          DropdownButtonFormField<String>(
                            value: selectedDistrict,
                            hint: Text("Select District", style: GoogleFonts.poppins(fontSize: 14)),
                            items: districts.map((d) {
                              return DropdownMenuItem(
                                  value: d, child: Text(d, style: GoogleFonts.poppins(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedDistrict = val),
                            decoration: const InputDecoration(
                              labelText: "District",
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),

                          const SizedBox(height: 28),

                          /// SIGN UP ACTION BUTTON
                          Container(
                            height: 54,
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
                              onPressed: isLoading ? null : signup,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "SIGN UP",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  "Login",
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget input(TextEditingController c, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
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

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class CenterTheme {
  static const alignment = TextAlign.center;
}