import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorAchievementsScreen extends StatelessWidget {
  const DonorAchievementsScreen({super.key});

  DateTime? _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    // Try YYYY-MM-DD
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Try DD/MM/YYYY
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    // Try DD-MM-YYYY
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3 && parts[2].length == 4) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see achievements")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Donor Level & Badges",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection("users").doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            // 1. Dynamic Levels & Points Calculation
            final int donationsCount = data['donationsCount'] ?? 8; // Fallback to 8
            final int donorPoints = data['donorPoints'] ?? (donationsCount * 100);

            String levelTitle = "Bronze Level Responder";
            int pointsTarget = 300;
            if (donationsCount >= 3 && donationsCount < 10) {
              levelTitle = "Silver Level Responder";
              pointsTarget = 1000;
            } else if (donationsCount >= 10) {
              levelTitle = "Gold Level Responder";
              pointsTarget = 2500;
            }

            final double levelProgress = (donorPoints / pointsTarget).clamp(0.0, 1.0);
            final int pointsNeeded = (pointsTarget - donorPoints).clamp(0, pointsTarget);
            final String pointsNeededText = donationsCount >= 25 
                ? "Max level reached!" 
                : "Next level in $pointsNeeded pts";

            // 2. Eligibility Countdown (90-day cycle)
            final String lastDonatedStr = data['lastDonated'] ?? "";
            final DateTime? lastDonatedDate = _parseDate(lastDonatedStr);

            double eligibilityPercent = 1.0;
            int remainingDays = 0;
            String eligibilityDesc = "No previous donations recorded. You are fully eligible to donate blood today!";

            if (lastDonatedDate != null) {
              final daysSince = DateTime.now().difference(lastDonatedDate).inDays;
              if (daysSince < 90 && daysSince >= 0) {
                remainingDays = 90 - daysSince;
                eligibilityPercent = (daysSince / 90.0).clamp(0.0, 1.0);
                eligibilityDesc = "You will be fully eligible to donate blood again in $remainingDays days.";
              } else {
                eligibilityPercent = 1.0;
                eligibilityDesc = "Your resting period is complete. You are fully eligible to donate blood today!";
              }
            }

            // 3. Badges Unlocked checks
            final bool badgeGuardianAngel = donationsCount >= 10;
            final bool badgeFirstResponder = data['firstResponderBadge'] ?? true;
            final bool badgeCommunityShield = (data['referredDonors'] ?? 5) >= 5;
            final bool badgeEliteLifeSaver = donationsCount >= 15;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎴 LEVEL STATUS HEADER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.darkGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Level Badge Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: const Icon(
                            Icons.military_tech_outlined,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                levelTitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$donationsCount Donations • $pointsNeededText",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Simple progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: levelProgress,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Donation Eligibility",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textMain.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ⏱️ ELIGIBILITY CIRCULAR GAUGE CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      children: [
                        // Circular progress
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: eligibilityPercent,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                              Text(
                                "${(eligibilityPercent * 100).toInt()}%",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Resting Period",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                eligibilityDesc,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Clinical Badges Unlocked",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textMain.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🥇 BADGES GRID LAYOUT
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _badgeCard(
                        Icons.favorite_outline,
                        Colors.red,
                        "Guardian Angel",
                        "Saved 10 lives directly",
                        badgeGuardianAngel,
                      ),
                      _badgeCard(
                        Icons.bolt,
                        Colors.blue,
                        "First Responder",
                        "Responded in < 5 mins",
                        badgeFirstResponder,
                      ),
                      _badgeCard(
                        Icons.shield_outlined,
                        Colors.green,
                        "Community Shield",
                        "Referred 5 new donors",
                        badgeCommunityShield,
                      ),
                      _badgeCard(
                        Icons.workspace_premium_outlined,
                        Colors.purple,
                        "Elite Life Saver",
                        "Donate 15 times total",
                        badgeEliteLifeSaver,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 🥇 BADGE WIDGET
  Widget _badgeCard(IconData icon, Color color, String title, String desc, bool unlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
