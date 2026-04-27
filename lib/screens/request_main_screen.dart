import 'package:flutter/material.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';

class RequestMainScreen extends StatefulWidget {
  const RequestMainScreen({super.key});

  @override
  State<RequestMainScreen> createState() => _RequestMainScreenState();
}

class _RequestMainScreenState extends State<RequestMainScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔥 TOP TAB (LIKE YOUR IMAGE)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _tabButton("Create", 0),
                  _tabButton("Manage", 1),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 CONTENT AREA
            Expanded(
              child: selectedTab == 0
                  ? const CreateRequestScreen()
                  : const MyRequestsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // 🔴 TAB BUTTON
  Widget _tabButton(String text, int index) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}