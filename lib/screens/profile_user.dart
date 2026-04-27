import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'phone_verify_screen.dart';

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  bool emailSending = false;
  bool emailVerified = false;

  @override
  void initState() {
    super.initState();
    checkEmail();
  }

  Future<void> checkEmail() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      emailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
  }

  Future<void> sendVerificationEmail() async {
    setState(() => emailSending = true);

    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Verification email sent")));

      await Future.delayed(const Duration(seconds: 30));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Try again later")));
    }

    setState(() => emailSending = false);
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          // 🔴 Gradient Header
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFA51313), Color(0xFFD32F2F)],
              ),
            ),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;

                // 🔥 Verification Logic
                bool phoneVerified =
                    FirebaseAuth.instance.currentUser!.phoneNumber != null;

                bool isFullyVerified = emailVerified && phoneVerified;

                return Column(
                  children: [
                    // 🔙 AppBar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            "Profile",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 🧑 Avatar
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Text(
                        data['bloodGroup'] ?? "",
                        style: const TextStyle(
                          color: Color(0xFFA51313),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      data['name'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ⚪ White Card
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // 📧 EMAIL ROW
                              Row(
                                children: [
                                  Expanded(
                                    child: _tile(
                                      Icons.email,
                                      "Email",
                                      data['email'] ?? "",
                                    ),
                                  ),

                                  emailVerified
                                      ? const Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                        )
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFFA51313,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFA51313),
                                            ),
                                          ),
                                          onPressed: emailSending
                                              ? null
                                              : sendVerificationEmail,
                                          child: emailSending
                                              ? const SizedBox(
                                                  height: 12,
                                                  width: 12,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text("Verify"),
                                        ),
                                ],
                              ),

                              const Divider(),

                              // 📱 PHONE ROW
                              Row(
                                children: [
                                  Expanded(
                                    child: _tile(
                                      Icons.phone,
                                      "Phone",
                                      data['phone'] ?? "",
                                    ),
                                  ),

                                  phoneVerified
                                      ? const Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                        )
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFFA51313,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFA51313),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PhoneVerifyScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text("Verify"),
                                        ),
                                ],
                              ),

                              const Divider(),

                              _tile(Icons.cake, "DOB", data['dob'] ?? ""),
                              const Divider(),

                              _tile(
                                Icons.bloodtype,
                                "Blood Group",
                                data['bloodGroup'] ?? "",
                              ),
                              const Divider(),

                              _tile(
                                Icons.calendar_today,
                                "Last Donated",
                                data['lastDonated'] ?? "",
                              ),
                              const Divider(),

                              _tile(
                                Icons.warning,
                                "Allergies",
                                data['allergies'] ?? "",
                              ),
                              const Divider(),

                              _tile(
                                Icons.medication,
                                "Medications",
                                data['medications'] ?? "",
                              ),
                              const Divider(),

                              _tile(
                                Icons.local_hospital,
                                "Diseases",
                                data['diseases'] ?? "",
                              ),
                              const Divider(),

                              _tile(
                                Icons.edit,
                                "Tattoo",
                                data['hasTattoo'] == true ? "Yes" : "No",
                              ),

                              const SizedBox(height: 20),

                              // ⚠ MESSAGE
                              if (!isFullyVerified)
                                const Text(
                                  "⚠ Verify email & phone to enable request",
                                  style: TextStyle(color: Colors.red),
                                ),

                              const SizedBox(height: 10),

                              // 🚨 REQUEST BUTTON
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFullyVerified
                                        ? const Color(0xFFA51313)
                                        : Colors.grey,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: isFullyVerified
                                      ? () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Request Sent"),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    isFullyVerified
                                        ? "Request Blood"
                                        : "Verification Required",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF2F2F2),
          child: Icon(icon, color: const Color(0xFFA51313), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
