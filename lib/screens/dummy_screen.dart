import 'package:flutter/material.dart';
import 'package:rapid_aid/screens/popup_card.dart';

class DummyScreen extends StatelessWidget {
  const DummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Center(child: PopupCard(bloodGroup: '', location: '', phone: '',))],
      ),
    );
  }
}
