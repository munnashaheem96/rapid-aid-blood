import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

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
    try {
      userPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  /// 🧠 USER DATA
  Future<void> loadUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        userBloodGroup = doc.data()?['bloodGroup'] ?? "";
        setState(() {});
      }
    } catch (_) {}
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
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";

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
    TextEditingController customController = TextEditingController(
      text: maxDistance != null ? maxDistance!.toInt().toString() : "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Filter Requests",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Blood Group",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ["All", "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
                                .map((e) => _chip(
                                      e,
                                      selectedBlood == e,
                                      () => setModal(() => selectedBlood = e),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "Urgency Status",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ["All", "Normal", "Urgent", "Critical"]
                                .map((e) => _chip(
                                      e,
                                      selectedUrgency == e,
                                      () => setModal(() => selectedUrgency = e),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "Max Distance",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [10, 20, 30, 50, 100]
                                .map((e) => _chip(
                                      "$e km",
                                      maxDistance == e.toDouble(),
                                      () => setModal(() => maxDistance = e.toDouble()),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Custom Distance (km)",
                              hintText: "Enter custom radius limit",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            setModal(() {
                              selectedBlood = "All";
                              selectedUrgency = "All";
                              maxDistance = null;
                              customController.clear();
                            });
                          },
                          child: Text("Reset", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              if (customController.text.isNotEmpty) {
                                maxDistance = double.tryParse(customController.text);
                              }
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: Text("Apply Filters", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
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

    String blood = data['bloodGroup'] ?? "--";
    String urgency = data['urgency'] ?? "Normal";

    Color urgencyColor;
    Color urgencyBg;

    if (urgency == "Critical") {
      urgencyColor = Colors.red.shade900;
      urgencyBg = Colors.red.shade50;
    } else if (urgency == "Urgent") {
      urgencyColor = Colors.orange.shade900;
      urgencyBg = Colors.orange.shade50;
    } else {
      urgencyColor = Colors.green.shade900;
      urgencyBg = Colors.green.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        children: [
          /// 🩸 BLOOD GROUP BADGE
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
            ),
            child: Center(
              child: Text(
                blood,
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? "Unknown Patient",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                ),
                Text(
                  data['hospital'] ?? "--",
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMain.withOpacity(0.9)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data['location'] ?? "--",
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// 🔥 DISTANCE + TIME
                Row(
                  children: [
                    Text(
                      "${distance.toStringAsFixed(1)} km",
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDateTime(data['createdAt']),
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urgency.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: urgencyColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => makeCall(data['phone'] ?? ""),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_in_talk, color: Colors.green.shade800, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,

      appBar: AppBar(
        title: const Text("Blood Requests"),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: openFilterSheet,
          ),
        ],
      ),

      body: Column(
        children: [
          // SEARCH INPUT BOX
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                hintText: "Search by patient, hospital, area...",
                prefixIcon: Icon(Icons.search_outlined),
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
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
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

                if (processed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, color: Colors.grey.shade400, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          "No requests matched",
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        Text(
                          "Try changing your search or filters",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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