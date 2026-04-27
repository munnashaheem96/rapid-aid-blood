import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
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
    userPosition = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  double getDistance(lat1, lon1, lat2, lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  void callNumber(String phone) async {
    final uri = Uri.parse("tel:$phone");
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // 🔥 FLOATING ADD BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Ambulance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAmbulanceScreen()),
          );
        },
      ),

      body: userPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔴 HERO HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency",
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Nearby Ambulances",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

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
                        padding: const EdgeInsets.all(16),
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
        color: isNearest ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isNearest ? Border.all(color: Colors.red, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),

      child: Column(
        children: [
          // 🔝 TOP ROW
          Row(
            children: [
              // 🚑 ICON
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital, color: Colors.red),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚗 VEHICLE
                    Text(
                      data['vehicleNo'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(data['driverName']),
                    Text(
                      data['organization'],
                      style: const TextStyle(color: Colors.grey),
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
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${distance.toStringAsFixed(1)} km",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 📞 CALL BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => callNumber(data['phone']),
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text(
                "Call Ambulance",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
