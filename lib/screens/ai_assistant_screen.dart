import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rapid_aid/services/ai_triage_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _presets = [
    "CPR Instructions",
    "Choking (Heimlich)",
    "Severe Bleeding",
    "Burn Treatment",
    "Heart Attack Signs"
  ];

  @override
  void initState() {
    super.initState();
  }

  String _currentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = query.trim();
    _messageController.clear();

    final userChatRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("ai_chats");

    try {
      await userChatRef.add({
        "text": text,
        "isUser": true,
        "createdAt": FieldValue.serverTimestamp(),
        "time": _currentTime(),
      });

      setState(() {
        _isTyping = true;
      });

      // Execute AI symptom triage
      final triageResult = await AiTriageService.triageSymptom(text);
      final firstAid = _getAiResponse(text);

      final buffer = StringBuffer();
      buffer.writeln("📋 **AI Symptom Triage Evaluation:**");
      buffer.writeln("• **Severity Priority**: ${triageResult.urgency}");
      buffer.writeln("• **Triage Confidence**: ${(triageResult.confidence * 100).toStringAsFixed(0)}%");
      buffer.writeln("• **Evaluation rationale**: ${triageResult.rationale}");
      buffer.writeln();
      buffer.writeln("🏥 **Triage Guidance Actions:**");
      if (triageResult.urgency == "Critical" || triageResult.urgency == "Mass Casualty") {
        buffer.writeln("🚨 **CRITICAL SHOCK THREAT DETECTED**: Dial 108 immediately or trigger the Family SOS emergency tracker.");
      } else {
        buffer.writeln("• Monitor vital metrics continuously. Seek professional medical consultation if symptoms persist.");
      }
      buffer.writeln();
      buffer.writeln("📚 **Verified Offline First Aid Steps:**");
      buffer.writeln(firstAid);

      final response = buffer.toString();

      await userChatRef.add({
        "text": response,
        "isUser": false,
        "createdAt": FieldValue.serverTimestamp(),
        "time": _currentTime(),
      });
    } catch (e) {
      debugPrint("Error sending AI message: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  String _getAiResponse(String query) {
    final normalized = query.toLowerCase();
    if (normalized.contains("cpr")) {
      return "🚨 **Cardiopulmonary Resuscitation (CPR) Guide:**\n\n"
          "1. **Call 108/Emergency** immediately.\n"
          "2. **Push Hard and Fast:** Place hands on the center of the chest and press down 2 to 2.4 inches (5-6 cm) at a rate of 100 to 120 compressions per minute.\n"
          "3. **Minimize Interruptions:** Keep chest compressions continuous until emergency help arrives.\n"
          "4. **Rescue Breaths (If trained):** Give 2 rescue breaths after every 30 chest compressions.";
    } else if (normalized.contains("chok") || normalized.contains("heimlich")) {
      return "🍎 **Choking (Heimlich Maneuver) Guide:**\n\n"
          "1. **Ask 'Are you choking?':** If they can speak or cough, encourage them to cough.\n"
          "2. **Stand Behind:** Wrap your arms around the person's waist, leaning them slightly forward.\n"
          "3. **Make a Fist:** Place your fist slightly above the navel (belly button).\n"
          "4. **Perform Thrusts:** Grasp the fist with your other hand and press into the abdomen with quick, upward thrusts.\n"
          "5. **Repeat** until the object is expelled or they lose consciousness (if so, transition to CPR).";
    } else if (normalized.contains("bleed") || normalized.contains("blood")) {
      return "🩸 **Severe Bleeding First Aid:**\n\n"
          "1. **Apply Direct Pressure:** Use a clean cloth, sterile dressing, or your hand to apply firm, constant pressure directly to the wound.\n"
          "2. **Elevate:** If possible, elevate the injured limb above heart level.\n"
          "3. **Add Dressing:** If blood leaks through the cloth, add another layer on top; do not remove the original dressing.\n"
          "4. **Tourniquet (Last resort):** Apply a tourniquet high and tight on the limb if bleeding does not stop and is life-threatening.";
    } else if (normalized.contains("burn")) {
      return "🔥 **Thermal Burn Treatment Guide:**\n\n"
          "1. **Cool the Burn:** Run cool (not cold) clean water over the burn for 10 to 20 minutes. Do not use ice.\n"
          "2. **Protect the Area:** Cover the burn loosely with a sterile, non-stick gauze bandage.\n"
          "3. **Avoid Ointments:** Do not apply butter, oil, toothpaste, or adhesive bandages directly on the fresh burn.\n"
          "4. **Call Medical Assistance** if the skin is charred, blistered over a large area, or on the face, hands, or joints.";
    } else if (normalized.contains("heart") || normalized.contains("cardiac")) {
      return "🫀 **Heart Attack Warning Signs & Action:**\n\n"
          "**Symptoms:**\n"
          "• Chest discomfort/pressure (feels like squeezing or pain in the center).\n"
          "• Pain radiating to jaw, neck, back, or left arm.\n"
          "• Shortness of breath, cold sweat, lightheadedness, or nausea.\n\n"
          "**Immediate Action:**\n"
          "1. **Call 108/Emergency Services** immediately.\n"
          "2. Keep the person calm, sitting, and resting.\n"
          "3. Have them chew an Aspirin (325mg) if they are not allergic and have no contraindications.";
    }

    return "I recommend contacting emergency support services immediately if you're facing a critical event. \n\nFor general advice, try asking about **CPR**, **Choking**, **Bleeding**, **Burns**, or **Heart Attack** symptoms.";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to use the AI Assistant")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "First-Aid AI Assistant",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preset suggestion chips at top
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _presets[index],
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                      backgroundColor: AppTheme.primaryLight,
                      side: BorderSide(color: AppTheme.primary.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _sendMessage(_presets[index]),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // Messages chat list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .collection("ai_chats")
                    .orderBy("createdAt", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final List<Map<String, dynamic>> messagesList = [];

                  if (docs.isEmpty) {
                    messagesList.add({
                      "text": "Hello! I am your RapidAid AI first-aid assistant. How can I help you handle a medical situation today?",
                      "isUser": false,
                      "time": _currentTime(),
                    });
                  } else {
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      messagesList.add({
                        "text": data["text"] ?? "",
                        "isUser": data["isUser"] == true,
                        "time": data["time"] ?? "",
                      });
                    }
                  }

                  // Auto scroll to bottom
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messagesList.length,
                    itemBuilder: (context, index) {
                      final msg = messagesList[index];
                      final isUser = msg["isUser"] == true;

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.charcoal : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                            ),
                            border: isUser ? null : Border.all(color: Colors.grey.shade100, width: 1),
                            boxShadow: AppTheme.premiumShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg["text"],
                                style: GoogleFonts.poppins(
                                  color: isUser ? Colors.white : AppTheme.textMain,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  msg["time"],
                                  style: GoogleFonts.poppins(
                                    color: isUser ? Colors.white54 : AppTheme.textSecondary.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
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

            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        "Assistant is typing",
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),

            // Message box input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: "Type medical question (e.g. CPR)...",
                        hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
