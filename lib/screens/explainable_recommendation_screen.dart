import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class ExplainableRecommendationScreen extends StatelessWidget {
  final Map<String, dynamic> hospitalDetails;

  const ExplainableRecommendationScreen({
    super.key,
    required this.hospitalDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Extracted details with fallbacks
    final String hospitalName = hospitalDetails['name'] ?? "Apollo Trauma Centre";
    final int finalScore = hospitalDetails['finalScore'] ?? 94;
    final int etaMinutes = hospitalDetails['etaMinutes'] ?? 6;
    final String reasons = hospitalDetails['reasons'] ?? "Close proximity (2.8 km), Low traffic congestion along route, Required blood group (O-) available in active grid";

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "AI Routing Reasoner",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Circular Gauge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      "ROUTING CONFIDENCE",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: finalScore / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$finalScore%",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Match Score",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      hospitalName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Estimated Transit ETA: $etaMinutes mins",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Explainable AI Reasoning (XAI)",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 16),

              // Reasoning list cards
              ...reasons.split(',').map((reason) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.green.shade700, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          reason.trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textMain,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Score metrics breakdown lists
              Text(
                "Optimization Breakdown",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 16),

              _metricRow("Distance Proximity (30%)", 0.95, "2.8 km away"),
              const SizedBox(height: 12),
              _metricRow("Traffic Congestion (20%)", 0.88, "Low Delay"),
              const SizedBox(height: 12),
              _metricRow("Blood Stock Matching (25%)", 1.0, "O- Units available"),
              const SizedBox(height: 12),
              _metricRow("ICU Readiness (15%)", 1.0, "Beds Available"),
              const SizedBox(height: 12),
              _metricRow("Specialist Availability (10%)", 0.9, "Cardiology on-call"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String name, double val, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain),
              ),
              Text(
                status,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val,
              minHeight: 5,
              backgroundColor: Colors.grey.shade100,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
