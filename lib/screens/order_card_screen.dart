import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderCardScreen extends StatelessWidget {
  final addressController = TextEditingController();

  OrderCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Card")),
      body: Column(
        children: [
          TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: "Address"),
          ),

          ElevatedButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser!.uid;

              await FirestoreService().orderCard({
                "userId": uid,
                "address": addressController.text,
                "type": "QR + NFC",
                "status": "pending",
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Order placed")),
              );
            },
            child: const Text("Order Now"),
          )
        ],
      ),
    );
  }
}