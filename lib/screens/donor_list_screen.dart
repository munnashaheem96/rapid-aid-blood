import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

enum FilterMode { nearby, district, state }

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  FilterMode mode = FilterMode.nearby;

  String selectedBlood = "All";
  bool showAvailableOnly = false;

  /// JSON LOCATION
  Map<String, dynamic> locationData = {};
  List<String> states = [];
  List<String> districts = [];

  String? selectedState;
  String? selectedDistrict;

  Position? currentPosition;

  final List<String> bloodGroups = [
    "All",
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
    loadLocation();
    getLocation();
  }

  Future<void> loadLocation() async {
    final response = await rootBundle.loadString('assets/india_locations.json');

    final data = jsonDecode(response);

    setState(() {
      locationData = data;
      states = data.keys.toList();
    });
  }

  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (_) {}
  }

  double distance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    var dLat = (lat2 - lat1) * pi / 180;
    var dLon = (lon2 - lon1) * pi / 180;

    var a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    return 2 * R * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text("Find Donors"),
        backgroundColor: Colors.red,
        elevation: 0,
      ),

      body: Column(
        children: [
          /// 🔥 FILTER CARD
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                /// MODE CHIPS
                Wrap(
                  spacing: 8,
                  children: [
                    _chip("Nearby", FilterMode.nearby),
                    _chip("District", FilterMode.district),
                    _chip("State", FilterMode.state),
                  ],
                ),

                const SizedBox(height: 12),

                /// STATE + DISTRICT
                if (mode != FilterMode.nearby) ...[
                  DropdownButtonFormField(
                    value: selectedState,
                    hint: const Text("Select State"),
                    items: states.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedState = val;
                        districts = List<String>.from(locationData[val]);
                        selectedDistrict = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    value: selectedDistrict,
                    hint: const Text("Select District"),
                    items: districts.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedDistrict = val);
                    },
                  ),
                ],

                const SizedBox(height: 12),

                /// BLOOD FILTER + AVAILABILITY
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        value: selectedBlood,
                        items: bloodGroups.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedBlood = val!),
                        decoration: const InputDecoration(
                          labelText: "Blood Group",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        const Text("Available"),
                        Switch(
                          value: showAvailableOnly,
                          onChanged: (val) =>
                              setState(() => showAvailableOnly = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 📋 DONOR LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                List<Map<String, dynamic>> list = [];

                for (var doc in docs) {
                  var d = doc.data() as Map<String, dynamic>;

                  if (d['isDonor'] != true) continue;

                  if (selectedBlood != "All" &&
                      d['bloodGroup'] != selectedBlood)
                    continue;

                  if (showAvailableOnly && d['isAvailable'] != true) continue;

                  double? dist;

                  /// NEARBY
                  if (mode == FilterMode.nearby &&
                      currentPosition != null &&
                      d['lat'] != null &&
                      d['lng'] != null) {
                    dist = distance(
                      currentPosition!.latitude,
                      currentPosition!.longitude,
                      d['lat'],
                      d['lng'],
                    );

                    if (dist > 10) continue;
                  }

                  /// DISTRICT
                  if (mode == FilterMode.district &&
                      selectedDistrict != null &&
                      d['district'] != selectedDistrict)
                    continue;

                  /// STATE
                  if (mode == FilterMode.state &&
                      selectedState != null &&
                      d['state'] != selectedState)
                    continue;

                  d['distance'] = dist;
                  list.add(d);
                }

                list.sort((a, b) {
                  double da = a['distance'] ?? 999;
                  double db = b['distance'] ?? 999;
                  return da.compareTo(db);
                });

                if (list.isEmpty) {
                  return const Center(child: Text("No donors found"));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    var d = list[index];
                    return _donorCard(d);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔴 CHIP
  Widget _chip(String label, FilterMode m) {
    return ChoiceChip(
      label: Text(label),
      selected: mode == m,
      selectedColor: Colors.red,
      labelStyle: TextStyle(color: mode == m ? Colors.white : Colors.black),
      onSelected: (_) => setState(() => mode = m),
    );
  }

  /// 🩸 DONOR CARD UI
  Widget _donorCard(Map<String, dynamic> d) {
    bool isAvailable = d['isAvailable'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          /// BLOOD GROUP
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                d['bloodGroup'] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['name'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${d['district'] ?? ""}, ${d['state'] ?? ""}",
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    if (d['distance'] != null)
                      Text("📍 ${d['distance'].toStringAsFixed(1)} km"),

                    const SizedBox(width: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAvailable ? "Available" : "Not Available",
                        style: TextStyle(
                          color: isAvailable ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// CALL BUTTON
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
