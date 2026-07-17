import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() => _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState extends State<SettingsNotificationsScreen> {
  bool _enableVibration = true;
  bool _enableFlashlight = true;
  bool _autoNavigate = false;
  bool _overrideQuietHours = true;
  double _notificationVolume = 0.8;
  String _selectedRingtone = "Emergency Siren Loop";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Emergency Alert Settings",
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
              // Premium banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_outlined, color: Colors.amber, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Do-Not-Disturb (DND) Bypass",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Emergency alerts bypass DND filters automatically where supported by system capabilities.",
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Sound & Telemetry Alerts",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    // Volume slider
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Alert Volume", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Slider(
                        value: _notificationVolume,
                        activeColor: AppTheme.primary,
                        onChanged: (val) => setState(() => _notificationVolume = val),
                      ),
                    ),
                    const Divider(height: 16),
                    // Vibration Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _enableVibration,
                      activeColor: AppTheme.primary,
                      title: Text("Continuous Vibration", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("Long pulse vibration during calls", style: GoogleFonts.poppins(fontSize: 10)),
                      onChanged: (val) => setState(() => _enableVibration = val),
                    ),
                    const Divider(height: 16),
                    // Flashlight Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _enableFlashlight,
                      activeColor: AppTheme.primary,
                      title: Text("Flashlight Blinking", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("Blinks camera flash dynamically", style: GoogleFonts.poppins(fontSize: 10)),
                      onChanged: (val) => setState(() => _enableFlashlight = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Ringtone & Auto Actions",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    // Ringtone Picker
                    DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRingtone,
                        decoration: InputDecoration(
                          labelText: "Emergency Ringtone",
                          labelStyle: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                          border: InputBorder.none,
                        ),
                        items: ["Emergency Siren Loop", "Nuclear Siren Alert", "Hospital Call Tone"]
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.poppins(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRingtone = val);
                        },
                      ),
                    ),
                    const Divider(height: 16),
                    // Auto Navigate Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _autoNavigate,
                      activeColor: AppTheme.primary,
                      title: Text("Auto Navigation", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("Instantly route target map on acceptance", style: GoogleFonts.poppins(fontSize: 10)),
                      onChanged: (val) => setState(() => _autoNavigate = val),
                    ),
                    const Divider(height: 16),
                    // Quiet hours exception
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _overrideQuietHours,
                      activeColor: AppTheme.primary,
                      title: Text("Bypass Quiet Hours", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("Ring even during scheduled silent hours", style: GoogleFonts.poppins(fontSize: 10)),
                      onChanged: (val) => setState(() => _overrideQuietHours = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Emergency notification parameters updated.", style: GoogleFonts.poppins()),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    "SAVE PARAMETERS",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
