import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  /// 📍 LOCATION DATA
  Map<String, dynamic> locationData = {};
  List<String> states = [];
  bool loadingLocation = true;

  @override
  void initState() {
    super.initState();
    loadLocationData();
  }

  Future<void> loadLocationData() async {
    try {
      final response = await rootBundle.loadString('assets/india_locations.json');
      final data = jsonDecode(response);

      setState(() {
        locationData = data;
        states = data.keys.toList();
        loadingLocation = false;
      });
    } catch (e) {
      debugPrint("Error loading location data: $e");
      setState(() => loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("User data not found."));
          }
          bool isAvailable = data['isAvailable'] ?? false;

          return CustomScrollView(
            slivers: [
              // 🔴 PREMIUM EXPANDED HEADER
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.darkGradient,
                        ),
                      ),
                      // Glowing abstract background elements
                      Positioned(
                        right: -50,
                        top: -50,
                        child: CircleAvatar(
                          radius: 120,
                          backgroundColor: AppTheme.primary.withOpacity(0.08),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 43,
                              backgroundColor: AppTheme.primaryLight,
                              child: Text(
                                data['bloodGroup'] ?? "-",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryDark,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['name'] ?? "-",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['email'] ?? "",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 AVAILABILITY TOGGLE CARD
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: AppTheme.cardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 12,
                                color: isAvailable ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAvailable ? "Available Now" : "Not Available",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Ready to donate blood if requested",
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAvailable,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.green,
                              onChanged: (value) async {
                                final user = FirebaseAuth.instance.currentUser;
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(user!.uid)
                                    .set({
                                      "isAvailable": value,
                                      "lastActive": FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Medical Profile Details",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textMain.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // PROFILE INFO CARD
                      Container(
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          children: [
                            _editableTile(
                              Icons.email_outlined,
                              "Email Address",
                              "email",
                              data['email'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.phone_outlined,
                              "Phone Number",
                              "phone",
                              data['phone'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            /// 📍 LOCATION DROPDOWN TILE
                            _locationTile(data),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.cake_outlined,
                              "Date of Birth",
                              "dob",
                              data['dob'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.bloodtype_outlined,
                              "Blood Group",
                              "bloodGroup",
                              data['bloodGroup'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.calendar_today_outlined,
                              "Last Donated Date",
                              "lastDonated",
                              data['lastDonated'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.warning_amber_outlined,
                              "Allergies",
                              "allergies",
                              data['allergies'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.medication_outlined,
                              "Current Medications",
                              "medications",
                              data['medications'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.local_hospital_outlined,
                              "Chronic Diseases",
                              "diseases",
                              data['diseases'] ?? "",
                            ),
                            const Divider(height: 1, thickness: 0.5),

                            _editableTile(
                              Icons.brush_outlined,
                              "Tattoo/Body Piercings",
                              "hasTattoo",
                              data['hasTattoo'] == true ? "Yes" : "No",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 📍 LOCATION TILE
  Widget _locationTile(Map<String, dynamic> data) {
    String state = data['state'] ?? "Not set";
    String district = data['district'] ?? "Not set";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.map_outlined, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Location",
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  state == "Not set" && district == "Not set"
                      ? "Not set"
                      : "$district, $state",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
            onPressed: () => _showLocationDialog(data),
          ),
        ],
      ),
    );
  }

  /// 📍 LOCATION DIALOG
  Future<void> _showLocationDialog(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;

    String? selectedState = data['state'];
    String? selectedDistrict = data['district'];

    List<String> districts = selectedState != null && locationData.containsKey(selectedState)
        ? List<String>.from(locationData[selectedState])
        : [];

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(
                "Select Location",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: states.contains(selectedState) ? selectedState : null,
                    hint: Text("State", style: GoogleFonts.poppins()),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: states.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedState = val;
                        districts = val != null ? List<String>.from(locationData[val]) : [];
                        selectedDistrict = null;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: districts.contains(selectedDistrict) ? selectedDistrict : null,
                    hint: Text("District", style: GoogleFonts.poppins()),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: districts.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedDistrict = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (selectedState == null || selectedDistrict == null) return;

                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user!.uid)
                        .set({
                          "state": selectedState,
                          "district": selectedDistrict,
                          "updatedAt": FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ✏️ NORMAL EDIT TILE
  Widget _editableTile(
    IconData icon,
    String title,
    String fieldKey,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  value.isEmpty ? "Not set" : value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: value.isEmpty ? AppTheme.textSecondary.withOpacity(0.6) : AppTheme.textMain,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
            onPressed: () async {
              TextEditingController controller = TextEditingController(text: value);
              final user = FirebaseAuth.instance.currentUser;

              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    "Edit $title",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  content: fieldKey == "hasTattoo"
                      ? DropdownButtonFormField<String>(
                          value: value == "Yes" ? "Yes" : "No",
                          items: ["Yes", "No"].map((v) {
                            return DropdownMenuItem(value: v, child: Text(v, style: GoogleFonts.poppins()));
                          }).toList(),
                          onChanged: (val) {
                            controller.text = val ?? "No";
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        )
                      : TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Enter $title",
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        dynamic finalVal = controller.text.trim();
                        if (fieldKey == "hasTattoo") {
                          finalVal = finalVal == "Yes";
                        }
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user!.uid)
                            .set({
                              fieldKey: finalVal,
                              "updatedAt": FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
