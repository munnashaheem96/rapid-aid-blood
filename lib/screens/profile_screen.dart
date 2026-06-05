import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
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
    try {
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
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 💾 Save / Update profile
  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all details", style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.charcoal,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile Updated successfully", style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: $e", style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryDark,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgGrey,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile Details",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textMain.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            // FORM CONTAINER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  /// 👤 NAME
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 📞 PHONE
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🩸 BLOOD GROUP DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedBloodGroup,
                    items: bloodGroups.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBloodGroup = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Blood Group",
                      prefixIcon: Icon(Icons.bloodtype_outlined),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🤝 DONOR TOGGLE CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: AppTheme.cardDecoration(),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Available as Donor",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                ),
                subtitle: Text(
                  "Appear in search for blood requests",
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                ),
                activeColor: Colors.white,
                activeTrackColor: AppTheme.primary,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                value: isDonor,
                onChanged: (value) {
                  setState(() {
                    isDonor = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 40),

            /// 💾 SAVE BUTTON
            GestureDetector(
              onTap: saveProfile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Save Changes",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
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
}
