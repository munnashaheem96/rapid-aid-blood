import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  /// 📍 LOCATION DATA
  Map<String, dynamic> locationData = {};
  List<String> states = [];

  @override
  void initState() {
    super.initState();
    loadLocationData();
  }

  Future<void> loadLocationData() async {
    final response = await rootBundle.loadString('assets/india_locations.json');
    final data = jsonDecode(response);

    setState(() {
      locationData = data;
      states = data.keys.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          /// 🔴 HEADER
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFA51313), Color(0xFFD32F2F)],
              ),
            ),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;
                bool isAvailable = data['isAvailable'] ?? false;

                return Column(
                  children: [
                    /// 🔙 HEADER
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            "Profile",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// 🧑 AVATAR
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Text(
                        data['bloodGroup'] ?? "",
                        style: const TextStyle(
                          color: Color(0xFFA51313),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// 👤 NAME
                    Text(
                      data['name'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// 🟢 AVAILABILITY
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              isAvailable ? "Available Now" : "Not Available",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? Colors.green : Colors.red,
                              ),
                            ),
                          ),

                          Switch(
                            value: isAvailable,
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

                    /// ⚪ WHITE CARD
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _editableTile(
                                Icons.email,
                                "Email",
                                "email",
                                data['email'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.phone,
                                "Phone",
                                "phone",
                                data['phone'] ?? "",
                              ),
                              const Divider(),

                              /// 📍 LOCATION DROPDOWN TILE
                              _locationTile(data),

                              _editableTile(
                                Icons.cake,
                                "DOB",
                                "dob",
                                data['dob'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.bloodtype,
                                "Blood Group",
                                "bloodGroup",
                                data['bloodGroup'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.calendar_today,
                                "Last Donated",
                                "lastDonated",
                                data['lastDonated'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.warning,
                                "Allergies",
                                "allergies",
                                data['allergies'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.medication,
                                "Medications",
                                "medications",
                                data['medications'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.local_hospital,
                                "Diseases",
                                "diseases",
                                data['diseases'] ?? "",
                              ),
                              const Divider(),

                              _editableTile(
                                Icons.edit,
                                "Tattoo",
                                "hasTattoo",
                                data['hasTattoo'] == true ? "Yes" : "No",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 📍 LOCATION TILE
  Widget _locationTile(Map<String, dynamic> data) {
    String state = data['state'] ?? "Not set";
    String district = data['district'] ?? "Not set";

    return Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFF2F2F2),
              child: Icon(Icons.map, color: Color(0xFFA51313), size: 16),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Location",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "$district, $state",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFA51313)),
              onPressed: () => _showLocationDialog(data),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  /// 📍 LOCATION DIALOG
  Future<void> _showLocationDialog(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;

    String? selectedState = data['state'];
    String? selectedDistrict = data['district'];

    List<String> districts = selectedState != null
        ? List<String>.from(locationData[selectedState])
        : [];

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Location"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedState,
                    hint: const Text("State"),
                    items: states.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedState = val;
                        districts = List<String>.from(locationData[val]);
                        selectedDistrict = null;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedDistrict,
                    hint: const Text("District"),
                    items: districts.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
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
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedState == null || selectedDistrict == null)
                      return;

                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user!.uid)
                        .set({
                          "state": selectedState,
                          "district": selectedDistrict,
                          "updatedAt": FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
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
    TextEditingController controller = TextEditingController(text: value);

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF2F2F2),
          child: Icon(icon, color: const Color(0xFFA51313), size: 16),
        ),
        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value.isEmpty ? "Not set" : value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFFA51313)),
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;

            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Edit $title"),
                content: TextField(controller: controller),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user!.uid)
                          .set({
                            fieldKey: controller.text.trim(),
                            "updatedAt": FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
