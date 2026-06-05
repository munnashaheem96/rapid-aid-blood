import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

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
      SnackBar(
        content: Text("Order Placed Successfully", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green.shade800,
      ),
    );

    Navigator.pop(context);
  }

  void handleError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}", style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.primaryDark,
      ),
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
        SnackBar(
          content: Text("Please fill all details", style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.charcoal,
        ),
      );
      return;
    }

    openCheckout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shipping Address",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textMain.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            // 📦 ADDRESS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: address,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Shipping Address",
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pincode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Pincode",
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Order Summary",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textMain.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            // 💰 PRICE DETAILS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  _priceRow("Emergency NFC Card", cardPrice),
                  const SizedBox(height: 10),
                  _priceRow("Standard Delivery", delivery),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _priceRow("Total Amount", total, bold: true),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // 🔥 PAY BUTTON
            GestureDetector(
              onTap: startPayment,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Pay ₹$total",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔥 PRICE ROW HELPER
  Widget _priceRow(String title, int value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppTheme.textMain : AppTheme.textSecondary,
            fontSize: bold ? 15 : 14,
          ),
        ),
        Text(
          "₹$value",
          style: GoogleFonts.poppins(
            fontWeight: bold ? FontWeight.w800 : FontWeight.bold,
            color: bold ? AppTheme.primary : AppTheme.textMain,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}