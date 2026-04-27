import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRequestScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditRequestScreen({super.key, required this.docId, required this.data});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  late TextEditingController nameController;
  late TextEditingController hospitalController;
  late TextEditingController unitsController;
  late TextEditingController phoneController;
  late TextEditingController bystanderController;

  String urgency = "Normal";
  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.data['name'] ?? "");
    hospitalController = TextEditingController(
      text: widget.data['hospital'] ?? "",
    );
    unitsController = TextEditingController(
      text: widget.data['units']?.toString() ?? "",
    );
    phoneController = TextEditingController(text: widget.data['phone'] ?? "");
    bystanderController = TextEditingController(
      text: widget.data['bystander'] ?? "",
    );

    urgency = widget.data['urgency'] ?? "Normal";
  }

  Future<void> updateRequest() async {
    if (unitsController.text.isEmpty ||
        int.tryParse(unitsController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Units must be number")));
      return;
    }

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('blood_requests')
        .doc(widget.docId)
        .update({
          'name': nameController.text,
          'hospital': hospitalController.text,
          'units': int.parse(unitsController.text),
          'phone': phoneController.text,
          'bystander': bystanderController.text,
          'urgency': urgency,
        });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔙 BACK + TITLE
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "Edit Request",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// 🔥 FORM CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    _input(nameController, "Patient Name", Icons.person),
                    _input(
                      hospitalController,
                      "Hospital",
                      Icons.local_hospital,
                    ),
                    _input(
                      unitsController,
                      "Units",
                      Icons.bloodtype,
                      type: TextInputType.number,
                    ),
                    _input(
                      phoneController,
                      "Phone",
                      Icons.phone,
                      type: TextInputType.phone,
                    ),
                    _input(bystanderController, "Bystander", Icons.people),

                    const SizedBox(height: 15),

                    /// 🔽 URGENCY DROPDOWN
                    DropdownButtonFormField<String>(
                      value: urgency,
                      items: ["Normal", "Urgent", "Critical"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => urgency = val ?? "Normal"),
                      decoration: InputDecoration(
                        labelText: "Urgency",
                        prefixIcon: const Icon(Icons.warning),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// 🔴 UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: loading ? null : updateRequest,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "UPDATE REQUEST",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔧 MODERN INPUT
  Widget _input(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
