import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'add_ambulance_screen.dart';

class AmbulanceNearby extends StatefulWidget {
  const AmbulanceNearby({super.key});

  @override
  State<AmbulanceNearby> createState() => _AmbulanceNearbyState();
}

class _AmbulanceNearbyState extends State<AmbulanceNearby> {
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    try {
      userPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  double getDistance(lat1, lon1, lat2, lon2) {
    try {
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
    } catch (_) {
      return 0.0;
    }
  }

  void callNumber(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,

      // 🔥 FLOATING ADD BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text(
          "Add Ambulance",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAmbulanceScreen()),
          );
        },
      ),

      body: userPosition == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // 🔴 HERO HEADER WITH BACK BUTTON
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 44, 20, 28),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Emergency Dispatch",
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Nearby Ambulances",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔥 LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ambulances')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                      }

                      var docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No active ambulances registered",
                            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                          ),
                        );
                      }

                      docs.sort((a, b) {
                        var da = a.data() as Map<String, dynamic>;
                        var db = b.data() as Map<String, dynamic>;

                        double distA = getDistance(
                          userPosition!.latitude,
                          userPosition!.longitude,
                          da['location'].latitude,
                          da['location'].longitude,
                        );

                        double distB = getDistance(
                          userPosition!.latitude,
                          userPosition!.longitude,
                          db['location'].latitude,
                          db['location'].longitude,
                        );

                        return distA.compareTo(distB);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;

                          double distance = getDistance(
                            userPosition!.latitude,
                            userPosition!.longitude,
                            data['location'].latitude,
                            data['location'].longitude,
                          );

                          return _premiumCard(data, distance, index == 0);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _premiumCard(
    Map<String, dynamic> data,
    double distance,
    bool isNearest,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNearest ? const Color(0xFFFFF3F3) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isNearest ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade100,
          width: isNearest ? 1.5 : 1,
        ),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        children: [
          // 🔝 TOP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🚑 ICON
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_hospital_outlined, color: AppTheme.primary, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚗 VEHICLE
                    Text(
                      data['vehicleNo'] ?? "--",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['driverName'] ?? "Unknown Driver",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textMain.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      data['organization'] ?? "--",
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // 📍 DISTANCE BADGE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.charcoal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${distance.toStringAsFixed(1)} km",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 📞 CALL BUTTON
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppTheme.emeraldGradient,
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => callNumber(data['phone'] ?? ""),
              icon: const Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
              label: Text(
                "CALL AMBULANCE",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

