import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  String selectedBloodGroup = "A+";
  bool isDonor = true;
  bool isLoading = true;

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-",
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // 🔄 Load existing profile
  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data["name"] ?? "";
      phoneController.text = data["phone"] ?? "";
      selectedBloodGroup = data["bloodGroup"] ?? "A+";
      isDonor = data["isDonor"] ?? true;
    }

    setState(() {
      isLoading = false;
    });
  }

  // 💾 Save / Update profile
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final pos = await LocationService().getLocation();

    await FirestoreService().saveProfile(user!.uid, {
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "bloodGroup": selectedBloodGroup,
      "location": GeoPoint(pos.latitude, pos.longitude),
      "isDonor": isDonor,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile Updated")));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 👤 NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// 📞 PHONE
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// 🩸 BLOOD GROUP DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              items: bloodGroups.map((group) {
                return DropdownMenuItem(value: group, child: Text(group));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBloodGroup = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Blood Group",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// 🤝 DONOR TOGGLE
            SwitchListTile(
              title: const Text("Available as Donor"),
              value: isDonor,
              onChanged: (value) {
                setState(() {
                  isDonor = value;
                });
              },
            ),

            const SizedBox(height: 25),

            /// 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveProfile,
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
