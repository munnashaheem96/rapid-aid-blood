import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class SustainabilityMarketplaceScreen extends StatefulWidget {
  const SustainabilityMarketplaceScreen({super.key});

  @override
  State<SustainabilityMarketplaceScreen> createState() => _SustainabilityMarketplaceScreenState();
}

class _SustainabilityMarketplaceScreenState extends State<SustainabilityMarketplaceScreen> {
  // Mock installed states for plugins
  final Map<String, bool> _installedPlugins = {
    "Mental Health Support": false,
    "Telemedicine Consults": true, // Pre-installed for convenience
    "Women Safety Alerts": false,
    "Child Emergency Mode": false,
    "Animal Rescue Helpline": false,
  };

  final List<Map<String, dynamic>> _pluginsList = [
    {
      "title": "Mental Health Support",
      "desc": "On-demand therapy coordination and panic alleviation tools during traumatic scenarios.",
      "icon": Icons.psychology_outlined,
      "color": Colors.teal,
    },
    {
      "title": "Telemedicine Consults",
      "desc": "Direct digital video connection to emergency doctors when ambulance routing is in transit.",
      "icon": Icons.video_camera_front_outlined,
      "color": Colors.indigo,
    },
    {
      "title": "Women Safety Alerts",
      "desc": "Direct geolocated alert broadcast to nearby female responders and civil defense shields.",
      "icon": Icons.female_outlined,
      "color": Colors.pink,
    },
    {
      "title": "Child Emergency Mode",
      "desc": "High-priority pediatric ambulance dispatch and specialized child first-aid guidance overlays.",
      "icon": Icons.child_care_outlined,
      "color": Colors.amber,
    },
    {
      "title": "Animal Rescue Helpline",
      "desc": "Direct routing map markers and contact pipelines to veterinary responder networks.",
      "icon": Icons.pets_outlined,
      "color": Colors.brown,
    },
  ];

  void _togglePlugin(String title) {
    setState(() {
      final wasInstalled = _installedPlugins[title] ?? false;
      _installedPlugins[title] = !wasInstalled;
    });

    final isInstalled = _installedPlugins[title] ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isInstalled ? "$title plugin successfully installed!" : "$title plugin uninstalled.",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: isInstalled ? Colors.green : AppTheme.charcoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Sustainability & Marketplace",
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
              
              // 📊 Sustainability Statistics Header
              Text(
                "Rapid Aid National Impact",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _statCard("1,420+", "Lives Saved", Icons.favorite, Colors.red),
                  const SizedBox(width: 16),
                  _statCard("8,940 hr", "Volunteer Time", Icons.access_time, Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCard("5.2 min", "Avg. Response", Icons.flash_on, Colors.yellow.shade700),
                  const SizedBox(width: 16),
                  _statCard("₹4.2M", "Economic Impact", Icons.currency_rupee, Colors.green),
                ],
              ),

              const SizedBox(height: 28),

              // 🔌 Plugin Marketplace title
              Text(
                "Rapid Aid Plugin Marketplace",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pluginsList.length,
                itemBuilder: (context, index) {
                  final plugin = _pluginsList[index];
                  final isInstalled = _installedPlugins[plugin['title']] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: plugin['color'].withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(plugin['icon'], color: plugin['color'], size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plugin['title'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plugin['desc'],
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInstalled ? Colors.grey.shade200 : AppTheme.primary,
                                  foregroundColor: isInstalled ? AppTheme.textMain : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _togglePlugin(plugin['title']),
                                child: Text(
                                  isInstalled ? "Active (Uninstall)" : "Install Plugin",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String metric, String desc, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textMain,
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
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
