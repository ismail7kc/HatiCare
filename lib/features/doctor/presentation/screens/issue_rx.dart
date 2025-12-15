import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/models/prescription_model.dart';
import 'package:haticare/features/doctor/presentation/viewModel/appointment_detailVM.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final AppointmentDetailvm appointmentDetailvm;

  const CreatePrescriptionScreen(this.appointmentDetailvm, {super.key});

  @override
  _IssueRxScreenState createState() => _IssueRxScreenState();
}

class _IssueRxScreenState extends State<CreatePrescriptionScreen> {
  List<Map<String, TextEditingController>> medicines = [
    {
      "name": TextEditingController(),
      "dose": TextEditingController(),
      "freq": TextEditingController(),
      "duration": TextEditingController(),
      "note": TextEditingController(),
    },
  ];

  void _addAnotherMedicine() {
    setState(() {
      medicines.add({
        "name": TextEditingController(),
        "dose": TextEditingController(),
        "freq": TextEditingController(),
        "duration": TextEditingController(),
        "note": TextEditingController(),
      });
    });
  }

  List<DoctorMedication> getMedicationsFromControllers() {
    return medicines.map((med) {
      return DoctorMedication(
        name: med['name']?.text ?? '',
        dose: med['dose']?.text ?? '',
        frequency: med['freq']?.text ?? '',
        duration: med['duration']?.text ?? '',
        notes: med['note']?.text ?? '',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Issue Rx", style: TextStyle(color: Colors.black)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Please fill in the details of the medicine.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 18),

                    for (int i = 0; i < medicines.length; i++) ...[
                      Text(
                        "Med ${i + 1}:",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _input("Name", medicines[i]["name"]!),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _input("Dose", medicines[i]["dose"]!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _input("Frequency", medicines[i]["freq"]!),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _input(
                              "Duration",
                              medicines[i]["duration"]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _multiInput("Notes", medicines[i]["note"]!),
                      const SizedBox(height: 20),
                    ],

                    // Add Another button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: _addAnotherMedicine,
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: const Text("Add Another"),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final meds = getMedicationsFromControllers();
                    final response = await widget.appointmentDetailvm
                        .createPrescription(medications: meds);
                        
                    if (!mounted) return;

                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          response['success'] == true ? 'Success' : 'Error',
                        ),
                        content: Text(
                          response['message'] ??
                              (response['success'] == true
                                  ? 'Prescription sent successfully!'
                                  : 'Something went wrong'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Issue Rx"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              isDense: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _multiInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              isDense: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
