import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rapid_aid/screens/all_requests_screen.dart';
import 'package:rapid_aid/screens/ambulance_nearby.dart';
import 'package:rapid_aid/screens/create_request_screen.dart';
import 'package:rapid_aid/screens/donor_list_screen.dart';
import 'package:rapid_aid/screens/dummy_screen.dart';
import 'package:rapid_aid/screens/emergency_card_screen.dart';
import 'package:rapid_aid/screens/request_main_screen.dart';
import 'package:rapid_aid/widgets/profile_card.dart';
import 'package:rapid_aid/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String location = "Fetching location...";
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    try {
      userPosition = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        userPosition!.latitude,
        userPosition!.longitude,
      );

      if (!mounted) return;

      setState(() {
        location =
            "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => location = "Error getting location");
    }
  }

  Future<String> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "Location OFF";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return "Permission denied";
    }

    Position position = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];
    return "${place.locality}, ${place.administrativeArea}";
  }

  // 🔥 SORT BY DISTANCE
  Future<List> sortByDistance(List docs) async {
    Position userPosition = await Geolocator.getCurrentPosition();

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;

      double lat = data['lat'] ?? 0;
      double lng = data['lng'] ?? 0;

      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        lat,
        lng,
      );

      data['distance'] = distance;
    }

    docs.sort((a, b) {
      double d1 = (a.data() as Map)['distance'];
      double d2 = (b.data() as Map)['distance'];
      return d1.compareTo(d2);
    });

    return docs;
  }

  // 🔥 PREMIUM REQUEST CARD (UPDATED)
  Widget buildRequestCard(Map<String, dynamic> data) {
    double distanceKm = 0;

    if (userPosition != null && data['lat'] != null && data['lng'] != null) {
      double meters = Geolocator.distanceBetween(
        userPosition!.latitude,
        userPosition!.longitude,
        data['lat'],
        data['lng'],
      );

      distanceKm = meters / 1000;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🩸 BLOOD GROUP
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data['bloodGroup'] ?? "--",
                style: const TextStyle(
                  color: Color(0xFFA51313),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
                  data['name'] ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data['location'] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                /// 🔥 DISTANCE FIXED
                Text(
                  "${distanceKm.toStringAsFixed(1)} km away",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),

          /// RIGHT SIDE
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['urgency'] ?? "Normal",
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFA51313),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: Colors.white, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await logout();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: showLogoutDialog,
                            child: const Icon(Icons.logout, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ProfileCard(
                    name: data['name'] ?? "",
                    bloodGroup: data['bloodGroup'] ?? "",
                    dob: data['dob'] ?? "",
                    lastDonated: data['lastDonated'] ?? "",
                    location: location,
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmergencyCardScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 🪪 ICON / IMAGE
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // 📝 TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Emergency Card",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Carry your medical info anywhere",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ➡️ ARROW
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quick Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildCategory('SOS', Icons.qr_code),
                      buildCategory('Ambulance', Icons.local_hospital),
                      buildCategory('Volunteer', Icons.people),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Blood Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllRequestsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "View More",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('blood_requests')
                        .orderBy('createdAt', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text("No requests"));
                      }

                      return ListView.separated(
                        shrinkWrap: true, // 🔥 IMPORTANT
                        physics:
                            const NeverScrollableScrollPhysics(), // 🔥 IMPORTANT
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12), // ✅ FIXED
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          return buildRequestCard(data);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildCategory(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == 'SOS') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestMainScreen()),
          );
        } else if (title == 'Ambulance') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AmbulanceNearby()),
          );
        } else if (title == 'Volunteer') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DonorListScreen()),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}
