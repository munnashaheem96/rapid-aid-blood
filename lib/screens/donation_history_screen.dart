import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view donation history")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Donation History",
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
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final String lastDonatedStr = data['lastDonated'] ?? "";
            
            // Calculate eligibility
            DateTime? lastDonatedDate;
            try {
              if (lastDonatedStr.isNotEmpty) {
                lastDonatedDate = DateTime.parse(lastDonatedStr);
              }
            } catch (_) {}

            int remainingDays = 0;
            bool isEligible = true;
            if (lastDonatedDate != null) {
              final diff = DateTime.now().difference(lastDonatedDate).inDays;
              if (diff < 90) {
                remainingDays = 90 - diff;
                isEligible = false;
              }
            }

            // Mock historical donation list
            final List<Map<String, dynamic>> history = [
              {
                "id": "TXN_9821A",
                "date": lastDonatedDate ?? DateTime.now().subtract(const Duration(days: 95)),
                "units": 1,
                "hospital": "City General Hospital, Trauma Center",
                "recipient": "Ramesh Kumar (O+)"
              },
              {
                "id": "TXN_7322B",
                "date": DateTime.now().subtract(const Duration(days: 185)),
                "units": 1,
                "hospital": "Apex Blood Bank Hub",
                "recipient": "Sita Devi (A+)"
              }
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eligibility Banner Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isEligible ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isEligible ? Colors.green.shade200 : Colors.orange.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEligible ? Icons.check_circle_outline : Icons.hourglass_empty,
                          color: isEligible ? Colors.green.shade700 : Colors.orange.shade700,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEligible ? "You are Eligible!" : "Resting Period Active",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isEligible ? Colors.green.shade900 : Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEligible
                                    ? "Thank you for being ready. You can accept active alerts nearby."
                                    : "You must wait $remainingDays days before your next eligible donation.",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isEligible ? Colors.green.shade800 : Colors.orange.shade800,
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
                    "Past Donations Timeline",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final formattedDate = DateFormat('dd MMM yyyy').format(item['date']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: AppTheme.cardDecoration(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volunteer_activism, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['hospital'],
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Donated: ${item['units']} Unit • Date: $formattedDate",
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  Text(
                                    "Recipient: ${item['recipient']}",
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Certificate trigger
                                  GestureDetector(
                                    onTap: () => _simulateDownloadCertificate(context, item, data['name'] ?? "User"),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Download Lifesaver Certificate",
                                          style: GoogleFonts.poppins(
                                            color: AppTheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _simulateDownloadCertificate(BuildContext context, Map<String, dynamic> item, String donorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber),
            const SizedBox(width: 10),
            Text("Lifesaver Certificate", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Certificate Reference ID: ${item['id']}", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
            const Divider(height: 20),
            Text("This is to certify that:", style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 6),
            Text(donorName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text(
              "has successfully donated blood at ${item['hospital']} on ${DateFormat('dd MMM yyyy').format(item['date'])} for patient ${item['recipient']}.",
              style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins()),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 16),
            label: Text("Save PDF", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Certificate ${item['id']} saved to downloads.", style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
