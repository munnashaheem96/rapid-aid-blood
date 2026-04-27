import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final db = FirebaseFirestore.instance;

  // 👤 Save Profile
  Future<void> saveProfile(String uid, Map<String, dynamic> data) async {
    await db.collection('users').doc(uid).set(data);
  }

  // 📥 Get Profile
  Future<DocumentSnapshot> getProfile(String uid) async {
    return await db.collection('users').doc(uid).get();
  }

  // 🩸 Create Blood Request
  Future<void> createRequest(Map<String, dynamic> data) async {
    await db.collection('requests').add(data);
  }

  // 📡 Get Requests
  Stream<QuerySnapshot> getRequests() {
    return db.collection('requests')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // 💳 Order Card
  Future<void> orderCard(Map<String, dynamic> data) async {
    await db.collection('orders').add(data);
  }
}