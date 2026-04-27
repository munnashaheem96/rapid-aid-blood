import 'package:flutter/material.dart';
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
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final bloodGroupController = TextEditingController();
  final dobController = TextEditingController();
  final lastDonatedController = TextEditingController();

  final allergiesController = TextEditingController();
  final diseasesController = TextEditingController();
  final medicationsController = TextEditingController();

  bool hasTattoo = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // 🔔 Notification permission
    FirebaseMessaging.instance.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
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
                          keyboardType: TextInputType.phone,
                          decoration: input("Phone", Icons.phone),
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          decoration: input("Blood Group", Icons.bloodtype),
                          items:
                              [
                                'A+',
                                'A-',
                                'B+',
                                'B-',
                                'AB+',
                                'AB-',
                                'O+',
                                'O-',
                              ].map((bg) {
                                return DropdownMenuItem(
                                  value: bg,
                                  child: Text(bg),
                                );
                              }).toList(),
                          onChanged: (val) {
                            bloodGroupController.text = val!;
                          },
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: dobController,
                          readOnly: true,
                          decoration: input("Date of Birth", Icons.cake),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2005),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              dobController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            }
                          },
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: lastDonatedController,
                          readOnly: true,
                          decoration: input(
                            "Last Donated Date",
                            Icons.calendar_today,
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              lastDonatedController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            }
                          },
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: allergiesController,
                          decoration: input("Allergies", Icons.warning),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: medicationsController,
                          decoration: input("Medications", Icons.medication),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: diseasesController,
                          decoration: input("Diseases", Icons.local_hospital),
                        ),

                        const SizedBox(height: 15),

                        SwitchListTile(
                          title: const Text("Do you have a tattoo?"),
                          value: hasTattoo,
                          onChanged: (val) {
                            setState(() => hasTattoo = val);
                          },
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: input("Password", Icons.lock),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: input("Confirm Password", Icons.lock),
                        ),

                        const SizedBox(height: 25),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: isLoading ? null : signup,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "SIGN UP",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  // 🚀 LOCATION + TOKEN (FIXED)
  Future<Map<String, dynamic>> getUserMeta() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw Exception("Location permission denied");
    }

    Position pos = await Geolocator.getCurrentPosition();

    String? token = await FirebaseMessaging.instance.getToken();

    return {'lat': pos.latitude, 'lng': pos.longitude, 'fcmToken': token};
  }

  // 🔥 SIGNUP
  Future<void> signup() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        bloodGroupController.text.isEmpty ||
        dobController.text.isEmpty) {
      showSnack("Fill all required fields");
      return;
    }

    if (password != confirmPassword) {
      showSnack("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      Map<String, dynamic> meta;

      try {
        meta = await getUserMeta();
      } catch (e) {
        showSnack("Please allow location permission");
        setState(() => isLoading = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user!.uid)
          .set({
            'name': name,
            'email': email,
            'phone': phone,
            'bloodGroup': bloodGroupController.text,
            'dob': dobController.text,
            'lastDonated': lastDonatedController.text,
            'allergies': allergiesController.text,
            'medications': medicationsController.text,
            'diseases': diseasesController.text,
            'hasTattoo': hasTattoo,

            // 🔥 IMPORTANT
            'lat': meta['lat'],
            'lng': meta['lng'],
            'fcmToken': meta['fcmToken'],

            'createdAt': Timestamp.now(),
          });

      showSnack("Signup successful");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showSnack(e.toString());
    }

    setState(() => isLoading = false);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
