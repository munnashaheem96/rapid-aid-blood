import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Profile")),
      body: Column(
        children: [
          TextField(controller: nameController),
          TextField(controller: phoneController),

          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final pos = await LocationService().getLocation();

              await FirestoreService().saveProfile(user!.uid, {
                "name": nameController.text,
                "phone": phoneController.text,
                "bloodGroup": "A-",
                "location": GeoPoint(pos.latitude, pos.longitude),
                "isDonor": true,
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}