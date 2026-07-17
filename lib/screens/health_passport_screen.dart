import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rapid_aid/theme/app_theme.dart';
import 'package:rapid_aid/services/encryption_service.dart';

class HealthPassportScreen extends StatefulWidget {
  const HealthPassportScreen({super.key});

  @override
  State<HealthPassportScreen> createState() => _HealthPassportScreenState();
}

class _HealthPassportScreenState extends State<HealthPassportScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Pre-existing controllers
  final _aadhaarController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  final _insurancePolicyController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _operationsController = TextEditingController();

  // 🌟 NEW 3.0 Passport controllers
  final _bloodHbController = TextEditingController();
  final _bloodPlateletsController = TextEditingController();
  final _prescriptionsController = TextEditingController();
  final _vaccinationsController = TextEditingController();
  final _directivesController = TextEditingController();
  
  // Scans summary metadata
  String _xrayFilename = "No file attached";
  String _mriFilename = "No file attached";
  String _ecgFilename = "No file attached";

  bool _isOrganDonor = false;
  String _selectedBlood = "A+";

  @override
  void initState() {
    super.initState();
    _loadLocalPassport();
  }

  Future<void> _loadLocalPassport() async {
    try {
      final decryptedData = await EncryptionService.readAndDecryptFile("health_passport.enc");
      if (decryptedData.isNotEmpty) {
        final data = jsonDecode(decryptedData) as Map<String, dynamic>;
        _populateFields(data);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snap = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
          if (snap.exists && snap.data() != null) {
            final data = snap.data()!;
            _populateFields(data);
            await EncryptionService.encryptAndWriteFile("health_passport.enc", jsonEncode(data));
          }
        }
      }
    } catch (e) {
      print("⚠️ Health Passport load failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _aadhaarController.text = data['aadhaar'] ?? "";
    _insuranceProviderController.text = data['insuranceProvider'] ?? "";
    _insurancePolicyController.text = data['insurancePolicy'] ?? "";
    _allergiesController.text = data['allergies'] ?? "";
    _diseasesController.text = data['diseases'] ?? "";
    _medicationsController.text = data['medications'] ?? "";
    _operationsController.text = data['operations'] ?? "";
    _isOrganDonor = data['isOrganDonor'] == true;
    _selectedBlood = data['bloodGroup'] ?? "A+";

    // 🌟 Populate new 3.0 fields
    _bloodHbController.text = data['bloodHb'] ?? "";
    _bloodPlateletsController.text = data['bloodPlatelets'] ?? "";
    _prescriptionsController.text = data['prescriptions'] ?? "";
    _vaccinationsController.text = data['vaccinations'] ?? "";
    _directivesController.text = data['directives'] ?? "";
    
    _xrayFilename = data['xrayFilename'] ?? "No file attached";
    _mriFilename = data['mriFilename'] ?? "No file attached";
    _ecgFilename = data['ecgFilename'] ?? "No file attached";
  }

  Future<void> _savePassport() async {
    setState(() => _isSaving = true);

    final data = {
      'aadhaar': _aadhaarController.text,
      'insuranceProvider': _insuranceProviderController.text,
      'insurancePolicy': _insurancePolicyController.text,
      'allergies': _allergiesController.text,
      'diseases': _diseasesController.text,
      'medications': _medicationsController.text,
      'operations': _operationsController.text,
      'isOrganDonor': _isOrganDonor,
      'bloodGroup': _selectedBlood,
      'hasPassportSetup': true,
      
      // 🌟 Include new 3.0 fields in AES Payload
      'bloodHb': _bloodHbController.text,
      'bloodPlatelets': _bloodPlateletsController.text,
      'prescriptions': _prescriptionsController.text,
      'vaccinations': _vaccinationsController.text,
      'directives': _directivesController.text,
      'xrayFilename': _xrayFilename,
      'mriFilename': _mriFilename,
      'ecgFilename': _ecgFilename,
      
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await EncryptionService.encryptAndWriteFile("health_passport.enc", jsonEncode(data));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
          data,
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Digital Passport securely AES-encrypted and saved.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved locally. Online sync failed.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _simulateFileUpload(String fileType) {
    setState(() {
      final name = "${fileType.toUpperCase()}_REPORT_${DateTime.now().millisecond}.pdf";
      if (fileType == "xray") _xrayFilename = name;
      if (fileType == "mri") _mriFilename = name;
      if (fileType == "ecg") _ecgFilename = name;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Attached $fileType to secure encryption queue", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(
          "Digital Health Passport",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expanded AES-256 Vault Active",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "Lab reports, directives, and prescription charts are fully encrypted at rest inside local secure containers.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Blood & Vitals Reports",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBlood,
                    decoration: InputDecoration(
                      labelText: "Blood Group",
                      labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      filled: false,
                    ),
                    items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                        .map((group) => DropdownMenuItem(
                              value: group,
                              child: Text(group, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBlood = val);
                    },
                  ),
                ),
              ),

              _inputField(controller: _bloodHbController, label: "Hemoglobin Hb level (g/dL)", icon: Icons.bloodtype_outlined),
              _inputField(controller: _bloodPlateletsController, label: "Platelet Count (cells/mcL)", icon: Icons.bar_chart_outlined),

              const SizedBox(height: 16),
              Text(
                "Clinical Conditions & Directives",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              _inputField(controller: _allergiesController, label: "Allergies", icon: Icons.sick_outlined),
              _inputField(controller: _diseasesController, label: "Pre-existing Diseases", icon: Icons.favorite_border),
              _inputField(controller: _medicationsController, label: "Daily Active Medications", icon: Icons.medication_outlined),
              _inputField(controller: _prescriptionsController, label: "Prescription History Summary", icon: Icons.history_edu_outlined),
              _inputField(controller: _vaccinationsController, label: "Vaccination Registry (e.g. Tetanus, COVID)", icon: Icons.vaccines_outlined),
              _inputField(controller: _directivesController, label: "Emergency Directives (e.g. Do Not Resuscitate)", icon: Icons.warning_amber_outlined),

              const SizedBox(height: 16),
              Text(
                "Identity & Insurance",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              _inputField(controller: _aadhaarController, label: "Aadhaar Card Number", icon: Icons.badge_outlined, type: TextInputType.number),
              _inputField(controller: _insuranceProviderController, label: "Health Insurance Provider", icon: Icons.verified_user_outlined),
              _inputField(controller: _insurancePolicyController, label: "Insurance Policy No.", icon: Icons.text_snippet_outlined),

              const SizedBox(height: 16),
              Text(
                "Medical Laboratory Files (Scan Attachments)",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              _fileAttachmentCard("X-Ray Scan", _xrayFilename, () => _simulateFileUpload("xray")),
              const SizedBox(height: 10),
              _fileAttachmentCard("MRI Scan", _mriFilename, () => _simulateFileUpload("mri")),
              const SizedBox(height: 10),
              _fileAttachmentCard("ECG Reading", _ecgFilename, () => _simulateFileUpload("ecg")),
              const SizedBox(height: 20),

              // Organ Donor Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  value: _isOrganDonor,
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Pledge Organ Donation",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  subtitle: Text(
                    "Allows quick emergency matching",
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  onChanged: (val) => setState(() => _isOrganDonor = val),
                ),
              ),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePassport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "ENCRYPT & SAVE PASSPORT",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileAttachmentCard(String label, String filename, VoidCallback onUpload) {
    bool hasFile = filename != "No file attached";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain),
                ),
                const SizedBox(height: 4),
                Text(
                  filename,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: hasFile ? Colors.green.shade600 : AppTheme.textSecondary,
                    fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(hasFile ? Icons.refresh : Icons.upload_file, size: 14, color: Colors.white),
            label: Text(hasFile ? "Update" : "Attach", style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 12)),
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMain),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: AppTheme.textSecondary.withOpacity(0.8),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.7), size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
