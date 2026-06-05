import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'edit_request_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('blood_requests')
              .where('uid', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, color: Colors.grey.shade400, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "No requests created yet",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    Text(
                      "Switch to the 'Create' tab to post a new request",
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.7)),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,

                  /// 🔴 Swipe background
                  background: Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
                  ),

                  /// 🔥 DELETE LOGIC
                  confirmDismiss: (_) async {
                    bool confirm =
                        await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Delete Request", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            content: Text("Are you sure you want to permanently delete this request?", style: GoogleFonts.poppins()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (!confirm) return false;

                    try {
                      await FirebaseFirestore.instance
                          .collection('blood_requests')
                          .doc(doc.id)
                          .delete();

                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text("Request deleted", style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.charcoal,
                          ),
                        );
                      }

                      return true;
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Delete failed", style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.charcoal,
                          ),
                        );
                      }
                      return false;
                    }
                  },

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: AppTheme.premiumShadow,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔴 TOP ROW
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
                              ),
                              child: Text(
                                data['bloodGroup'] ?? "-",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Flexible(
                              child: Text(
                                "${data['units']?.toString() ?? "-"} units",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textMain,
                                ),
                              ),
                            ),

                            const Spacer(),

                            /// ✏️ EDIT BUTTON
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditRequestScreen(
                                      docId: doc.id,
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                            ),

                            /// URGENCY BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _urgencyBg(data['urgency']),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (data['urgency'] ?? "Normal").toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: _urgencyText(data['urgency']),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          data['name'] ?? "-",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          data['hospital'] ?? "-",
                          style: GoogleFonts.poppins(color: AppTheme.textMain.withOpacity(0.85), fontSize: 13),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data['location'] ?? "-",
                                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.person_pin_outlined,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Bystander: ${data['bystander'] ?? "-"}",
                                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.phone_in_talk_outlined,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data['phone'] ?? "-",
                              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _urgencyBg(String? urgency) {
    switch (urgency) {
      case "Critical":
        return Colors.red.shade50;
      case "Urgent":
        return Colors.orange.shade50;
      default:
        return Colors.green.shade50;
    }
  }

  Color _urgencyText(String? urgency) {
    switch (urgency) {
      case "Critical":
        return Colors.red.shade900;
      case "Urgent":
        return Colors.orange.shade900;
      default:
        return Colors.green.shade900;
    }
  }
}

