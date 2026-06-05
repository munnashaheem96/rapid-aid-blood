import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

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

  /// LOCATION JSON
  Map<String, dynamic> locationData = {};
  List<String> states = [];
  List<String> districts = [];

  String? selectedState;
  String? selectedDistrict;

  Position? currentPosition;
  bool locationLoading = true;

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

  /// LOAD JSON
  Future<void> loadLocation() async {
    try {
      final response = await rootBundle.loadString(
        'assets/india_locations.json',
      );

      final data = jsonDecode(response);

      setState(() {
        locationData = data;
        states = data.keys.toList();
      });
    } catch (e) {
      debugPrint("JSON LOAD ERROR: $e");
    }
  }

  /// GET USER LOCATION
  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => locationLoading = false);
        return;
      }

      currentPosition = await Geolocator.getCurrentPosition();
      setState(() => locationLoading = false);
    } catch (e) {
      debugPrint("LOCATION ERROR: $e");
      setState(() => locationLoading = false);
    }
  }

  /// DISTANCE CALCULATION
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
      backgroundColor: AppTheme.bgGrey,

      appBar: AppBar(
        title: const Text("Find Volunteers"),
      ),

      body: Column(
        children: [
          /// FILTER CARD
          _buildFilterCard(),

          /// LIST
          Expanded(
            child: locationLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _buildDonorList(),
          ),
        ],
      ),
    );
  }

  /// FILTER UI
  Widget _buildFilterCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter Criteria",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip("Nearby", FilterMode.nearby),
              _chip("District", FilterMode.district),
              _chip("State", FilterMode.state),
            ],
          ),

          const SizedBox(height: 16),

          if (mode != FilterMode.nearby) ...[
            DropdownButtonFormField<String>(
              value: selectedState,
              hint: Text("Select State", style: GoogleFonts.poppins(fontSize: 14)),
              items: states
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;

                setState(() {
                  selectedState = val;
                  districts = List<String>.from(locationData[val] ?? []);
                  selectedDistrict = null;
                });
              },
              decoration: const InputDecoration(labelText: "State"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedDistrict,
              hint: Text("Select District", style: GoogleFonts.poppins(fontSize: 14)),
              items: districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.poppins(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => selectedDistrict = val),
              decoration: const InputDecoration(labelText: "District"),
            ),

            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedBlood,
                  items: bloodGroups
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (val) => setState(() => selectedBlood = val!),
                  decoration: const InputDecoration(
                    labelText: "Blood Group",
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Available Only",
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Switch(
                    value: showAvailableOnly,
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.primary,
                    onChanged: (val) => setState(() => showAvailableOnly = val),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// DONOR LIST
  Widget _buildDonorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        var docs = snapshot.data!.docs;

        List<Map<String, dynamic>> list = [];

        for (var doc in docs) {
          var d = doc.data() as Map<String, dynamic>;

          /// SAFETY CHECKS
          if (d['isDonor'] != true) continue;

          if (selectedBlood != "All" && d['bloodGroup'] != selectedBlood)
            continue;

          if (showAvailableOnly && d['isAvailable'] != true) continue;

          double? dist;

          /// NEARBY FILTER
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

            if (dist > 50) continue;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_outlined, color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 12),
                Text(
                  "No volunteers found",
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                Text(
                  "Try adjusting your location filters",
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.7)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _donorCard(list[index]);
          },
        );
      },
    );
  }

  /// CHIP
  Widget _chip(String label, FilterMode m) {
    bool selected = mode == m;
    return GestureDetector(
      onTap: () => setState(() => mode = m),
      child: Container(
        width: (MediaQuery.of(context).size.width - 80) / 3,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// DONOR CARD
  Widget _donorCard(Map<String, dynamic> d) {
    bool isAvailable = d['isAvailable'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        children: [
          // 🩸 BLOOD GROUP BADGE
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
            ),
            child: Center(
              child: Text(
                d['bloodGroup'] ?? "",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['name'] ?? "No Name",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain),
                ),
                const SizedBox(height: 2),
                Text(
                  "${d['district'] ?? ""}, ${d['state'] ?? ""}",
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (d['distance'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        "${d['distance'].toStringAsFixed(1)} km away",
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // AVAILABILITY PILL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAvailable ? "ONLINE" : "OFFLINE",
              style: GoogleFonts.poppins(
                color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

