import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:rapid_aid/screens/home_screen.dart';
import 'package:rapid_aid/screens/login_screen.dart';
import 'package:rapid_aid/screens/profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> checkProfile(String uid) async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // ⏳ Loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnapshot.hasData) {
          return LoginScreen();
        }

        // ✅ Logged in → check profile
        final user = authSnapshot.data!;

        return FutureBuilder<bool>(
          future: checkProfile(user.uid),
          builder: (context, profileSnapshot) {

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.data == true) {
              return const HomeScreen(); // ✅ profile exists
            } else {
              return ProfileScreen(); // 🔥 force profile setup
            }
          },
        );
      },
    );
  }
}