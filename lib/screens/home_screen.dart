import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/screens/all_requests_screen.dart';
import 'package:rapid_aid/screens/ambulance_nearby.dart';
import 'package:rapid_aid/screens/family_sos_screen.dart';
import 'package:rapid_aid/screens/health_passport_screen.dart';
import 'package:rapid_aid/screens/donation_history_screen.dart';
import 'package:rapid_aid/screens/camera_guidance_screen.dart';
import 'package:rapid_aid/screens/citizen_registry_screen.dart';
import 'package:rapid_aid/screens/sustainability_marketplace_screen.dart';
import 'package:rapid_aid/screens/emergency_card_screen.dart';
import 'package:rapid_aid/screens/pharmacy_screen.dart';
import 'package:rapid_aid/screens/request_main_screen.dart';
import 'package:rapid_aid/widgets/profile_card.dart';
import 'package:rapid_aid/screens/login_screen.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'package:rapid_aid/screens/ai_assistant_screen.dart';
import 'package:rapid_aid/screens/radar_scanner_screen.dart';
import 'package:rapid_aid/screens/donor_achievements_screen.dart';
import 'package:rapid_aid/screens/settings_notifications_screen.dart';

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
        location = "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => location = "Location not available");
    }
  }

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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.12), width: 1),
            ),
            child: Center(
              child: Text(
                blood,
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                  data['name'] ?? "Unknown Patient",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data['location'] ?? "Nearby Location",
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${distanceKm.toStringAsFixed(1)} km away",
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(8),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 14),
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
        title: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to sign out?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await logout();
            },
            child: Text("Logout", style: GoogleFonts.poppins(color: Colors.white)),
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
      backgroundColor: AppTheme.bgGrey,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String firstName = (data['name'] ?? "").split(" ").first;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 1. TOP PREMIUM HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.primary, Colors.orange.shade400],
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: AppTheme.primary, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back,",
                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                firstName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _appBarIconButton(
                            icon: Icons.support_agent_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _appBarIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsNotificationsScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _appBarIconButton(
                            icon: Icons.logout_outlined,
                            onTap: showLogoutDialog,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. PROFILE PROFILE VIRTUAL CARD
                  ProfileCard(
                    name: data['name'] ?? "",
                    bloodGroup: data['bloodGroup'] ?? "",
                    dob: data['dob'] ?? "",
                    lastDonated: data['lastDonated'] ?? "",
                    location: location,
                  ),

                  const SizedBox(height: 20),

                  // 3. STATS HIGHLIGHT OVERLAY
                  Row(
                    children: [
                      _statsIndicator("Lives Saved", "14 rescued", Icons.favorite, Colors.red.shade400),
                      const SizedBox(width: 12),
                      _statsIndicator("Trust Index", "Level 4 (Elite)", Icons.stars, Colors.amber.shade600),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 4. CRISIS MANAGEMENT ACTIONS CARD
                  Text(
                    "Emergency Services Control",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 12),
                  
                  // Row of major quick actions
                  Row(
                    children: [
                      _actionCardExpanded("SOS Alert", "Create immediate broadcast", Icons.notification_important, Colors.red, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestMainScreen()));
                      }),
                      const SizedBox(width: 12),
                      _actionCardExpanded("Ambulance", "Locate responders nearby", Icons.local_hospital, Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AmbulanceNearby()));
                      }),
                      const SizedBox(width: 12),
                      _actionCardExpanded("Volunteers", "Radar donor match", Icons.radar, Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RadarScannerScreen(bloodGroup: data['bloodGroup'] ?? "A+")));
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 5. REGULAR UTILITIES CONTROL PANEL CARD
                  Text(
                    "Operations & Safety Tools",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: Column(
                      children: [
                        _utilityRowItem(
                          title: "Health Digital Passport",
                          desc: "Secure encrypted medical profile & MRIs",
                          icon: Icons.lock_outline,
                          iconColor: Colors.teal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthPassportScreen())),
                        ),
                        const Divider(height: 24, thickness: 0.8),
                        _utilityRowItem(
                          title: "Family SOS Standby",
                          desc: "Track and broadcast coordinates to network",
                          icon: Icons.shield_outlined,
                          iconColor: Colors.indigo,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilySosScreen())),
                        ),
                        const Divider(height: 24, thickness: 0.8),
                        _utilityRowItem(
                          title: "Sustainability & Plugins",
                          desc: "Browse Marketplace, verify volunteer hours",
                          icon: Icons.storefront_outlined,
                          iconColor: Colors.purple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SustainabilityMarketplaceScreen())),
                        ),
                        const Divider(height: 24, thickness: 0.8),
                        _utilityRowItem(
                          title: "Citizen Responder Registry",
                          desc: "Register in local CPR first-responder grid",
                          icon: Icons.app_registration_outlined,
                          iconColor: Colors.teal.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenRegistryScreen())),
                        ),
                        const Divider(height: 24, thickness: 0.8),
                        _utilityRowItem(
                          title: "Camera First-Aid AI",
                          desc: "Visual feedback boundaries overlay guide",
                          icon: Icons.videocam_outlined,
                          iconColor: Colors.blueGrey,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraGuidanceScreen())),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. PHARMACY RADIAL GLOW BUTTON CARD
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PharmacyScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.emeraldGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.24),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find Nearest Pharmacy',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Locate medical suppliers around your geofence',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 7. RECENT REQUEST STREAMS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Blood Requests',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AllRequestsScreen()),
                          );
                        },
                        child: Text(
                          "View More",
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('blood_requests')
                        .orderBy('createdAt', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              "No active emergency alerts nearby",
                              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return buildRequestCard(data);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _appBarIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
    );
  }

  Widget _statsIndicator(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMain, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCardExpanded(String title, String desc, IconData icon, Color baseColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: baseColor.withOpacity(0.08)),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: baseColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 8, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _utilityRowItem({
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
          ],
        ),
      ),
    );
  }
}
