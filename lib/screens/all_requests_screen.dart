import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AllRequestsScreen extends StatefulWidget {
  const AllRequestsScreen({super.key});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  Position? userPosition;

  String searchQuery = "";
  String selectedBlood = "All";
  String selectedUrgency = "All";
  double? maxDistance;

  String userBloodGroup = "";

  @override
  void initState() {
    super.initState();
    loadLocation();
    loadUserData();
  }

  /// 📍 LOCATION
  Future<void> loadLocation() async {
    userPosition = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  /// 🧠 USER DATA
  Future<void> loadUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      userBloodGroup = doc.data()?['bloodGroup'] ?? "";
      setState(() {});
    }
  }

  /// 📞 CALL
  Future<void> makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// 🕒 SMART DATE FORMAT
  String formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "";

    final date = timestamp.toDate();
    final now = DateTime.now();

    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";

    return DateFormat("dd MMM • hh:mm a").format(date);
  }

  /// 🔍 FILTER
  bool matchesFilter(Map<String, dynamic> data, double distanceKm) {
    final query = searchQuery.toLowerCase();

    return ((data['name'] ?? "").toLowerCase().contains(query) ||
            (data['hospital'] ?? "").toLowerCase().contains(query) ||
            (data['location'] ?? "").toLowerCase().contains(query)) &&
        (selectedBlood == "All" || data['bloodGroup'] == selectedBlood) &&
        (selectedUrgency == "All" || data['urgency'] == selectedUrgency) &&
        (maxDistance == null || distanceKm <= maxDistance!);
  }

  /// 🎛 FILTER SHEET (PREMIUM)
  void openFilterSheet() {
    TextEditingController customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [

                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Filter Requests",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text("Blood Group",
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),

                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              "All",
                              "A+",
                              "A-",
                              "B+",
                              "B-",
                              "O+",
                              "O-",
                              "AB+",
                              "AB-"
                            ]
                                .map((e) => _chip(
                                      e,
                                      selectedBlood == e,
                                      () => setModal(
                                          () => selectedBlood = e),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 16),

                          const Text("Urgency",
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),

                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ["All", "Normal", "Urgent", "Critical"]
                                .map((e) => _chip(
                                      e,
                                      selectedUrgency == e,
                                      () => setModal(
                                          () => selectedUrgency = e),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 16),

                          const Text("Distance",
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),

                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            children: [10, 20, 30, 40, 50]
                                .map((e) => _chip(
                                      "$e km",
                                      maxDistance == e.toDouble(),
                                      () => setModal(
                                          () => maxDistance = e.toDouble()),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Custom distance (km)",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModal(() {
                              selectedBlood = "All";
                              selectedUrgency = "All";
                              maxDistance = null;
                            });
                          },
                          child: const Text("Reset"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            if (customController.text.isNotEmpty) {
                              maxDistance = double.tryParse(
                                  customController.text);
                            }
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text("Apply"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// CHIP
  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Colors.red, Colors.redAccent])
              : null,
          color: selected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// 🎨 CARD
  Widget buildCard(Map<String, dynamic> data) {
    double distance = 0;

    if (userPosition != null &&
        data['lat'] != null &&
        data['lng'] != null) {
      distance =
          Geolocator.distanceBetween(userPosition!.latitude,
                  userPosition!.longitude, data['lat'], data['lng']) /
              1000;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFEBEE),
            child: Text(data['bloodGroup']),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'],
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                Text(data['hospital']),
                Text(data['location'],
                    style: const TextStyle(color: Colors.grey)),

                /// 🔥 DISTANCE + TIME
                Row(
                  children: [
                    Text("${distance.toStringAsFixed(1)} km"),
                    const SizedBox(width: 8),
                    Text(
                      formatDateTime(data['createdAt']),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => makeCall(data['phone']),
            child: const Icon(Icons.call, color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text("Blood Requests",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: openFilterSheet,
          ),
        ],
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blood_requests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final processed = snapshot.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  double dist = 0;

                  if (userPosition != null &&
                      d['lat'] != null &&
                      d['lng'] != null) {
                    dist =
                        Geolocator.distanceBetween(
                              userPosition!.latitude,
                              userPosition!.longitude,
                              d['lat'],
                              d['lng'],
                            ) /
                            1000;
                  }

                  return {"data": d, "distance": dist};
                }).where((e) {
                  final data = e["data"] as Map<String, dynamic>;
                  final distance = e["distance"] as double;
                  return matchesFilter(data, distance);
                }).toList();

                /// 🔥 SORT
                processed.sort((a, b) {
                  final A = a["data"] as Map<String, dynamic>;
                  final B = b["data"] as Map<String, dynamic>;

                  final dA = a["distance"] as double;
                  final dB = b["distance"] as double;

                  if (A['urgency'] == "Critical" &&
                      B['urgency'] != "Critical") {
                    return -1;
                  }
                  if (B['urgency'] == "Critical" &&
                      A['urgency'] != "Critical") {
                    return 1;
                  }

                  if (A['bloodGroup'] == userBloodGroup &&
                      B['bloodGroup'] != userBloodGroup) {
                    return -1;
                  }
                  if (B['bloodGroup'] == userBloodGroup &&
                      A['bloodGroup'] != userBloodGroup) {
                    return 1;
                  }

                  return dA.compareTo(dB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: processed.length,
                  itemBuilder: (_, i) {
                    return buildCard(processed[i]["data"] as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}