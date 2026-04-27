import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Razorpay _razorpay;

  final int cardPrice = 100;
  final int delivery = 40;

  int get total => cardPrice + delivery;

  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final pincode = TextEditingController();

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handleError);
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_xxxxxxxx', // 🔥 replace
      'amount': total * 100,
      'name': 'Rapid Aid',
      'description': 'Emergency NFC Card',
      'prefill': {
        'contact': phone.text,
      },
    };

    _razorpay.open(options);
  }

  // ✅ PAYMENT SUCCESS
  void handleSuccess(PaymentSuccessResponse response) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('card_orders').add({
      "uid": uid,
      "name": name.text,
      "phone": phone.text,
      "address": address.text,
      "pincode": pincode.text,
      "amount": total,
      "paymentId": response.paymentId,
      "status": "paid",
      "createdAt": Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order Placed Successfully")),
    );

    Navigator.pop(context);
  }

  void handleError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed")),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void startPayment() {
    if (name.text.isEmpty ||
        phone.text.isEmpty ||
        address.text.isEmpty ||
        pincode.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all details")),
      );
      return;
    }

    openCheckout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.red,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // 📦 ADDRESS CARD
            _card(
              child: Column(
                children: [
                  _input(name, "Full Name", Icons.person),
                  _divider(),

                  _input(phone, "Phone", Icons.phone,
                      type: TextInputType.phone),
                  _divider(),

                  _input(address, "Address", Icons.location_on),
                  _divider(),

                  _input(pincode, "Pincode", Icons.pin,
                      type: TextInputType.number),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 💰 PRICE DETAILS
            _card(
              child: Column(
                children: [
                  _priceRow("Card Price", cardPrice),
                  _priceRow("Delivery", delivery),
                  const Divider(),
                  _priceRow("Total", total, bold: true),
                ],
              ),
            ),

            const Spacer(),

            // 🔥 PAY BUTTON
            GestureDetector(
              onTap: startPayment,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "Pay ₹$total",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 UI HELPERS

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.red),
        hintText: hint,
        border: InputBorder.none,
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 20);
  }

  Widget _priceRow(String title, int value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          "₹$value",
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}