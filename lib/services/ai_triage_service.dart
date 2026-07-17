import 'dart:convert';
import 'package:http/http.dart' as http;

class TriageResult {
  final String urgency;
  final double confidence;
  final String rationale;

  TriageResult({
    required this.urgency,
    required this.confidence,
    required this.rationale,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      urgency: json['urgency'] ?? 'Normal',
      confidence: (json['confidence'] ?? 0.8).toDouble(),
      rationale: json['rationale'] ?? 'AI classification completed.',
    );
  }
}

class AiTriageService {
  static const String _backendUrl = "https://rapid-aid-backend.onrender.com/triage";

  /// Triages patient symptoms online by calling the backend AI engine.
  /// Automatically falls back to offline keyword triage if network is unavailable.
  static Future<TriageResult> triageSymptom(String notes, {int units = 1, String bloodGroup = "A+"}) async {
    if (notes.trim().isEmpty) {
      return TriageResult(
        urgency: "Normal",
        confidence: 1.0,
        rationale: "No notes provided. Defaulted to normal priority.",
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "notes": notes,
          "units": units,
          "bloodGroup": bloodGroup,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        return TriageResult.fromJson(parsed);
      } else {
        throw Exception("Server returned code ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ AI Triage request failed, executing local offline triage: $e");
      return _localOfflineTriage(notes, units);
    }
  }

  /// Rules-based local triage matching critical indicators for offline safety.
  static TriageResult _localOfflineTriage(String notes, int units) {
    final normalized = notes.toLowerCase();
    
    if (normalized.contains("cpr") || 
        normalized.contains("cardiac") || 
        normalized.contains("heart attack") || 
        normalized.contains("stroke") || 
        normalized.contains("unconscious") || 
        normalized.contains("heavy bleeding") || 
        normalized.contains("accident") || 
        units >= 5) {
      return TriageResult(
        urgency: "Critical",
        confidence: 0.85,
        rationale: "[Offline Mode] Classified as Critical due to detected life-threatening keywords (CPR, Cardiac, Accident, unconscious, heavy bleeding).",
      );
    }
    
    if (normalized.contains("chok") || 
        normalized.contains("fracture") || 
        normalized.contains("burn") || 
        normalized.contains("poison") || 
        units >= 3) {
      return TriageResult(
        urgency: "Urgent",
        confidence: 0.80,
        rationale: "[Offline Mode] Classified as Urgent due to acute conditions (choking, fracture, burn).",
      );
    }

    return TriageResult(
      urgency: "Normal",
      confidence: 0.75,
      rationale: "[Offline Mode] Classified as Normal based on description analysis.",
    );
  }
}
