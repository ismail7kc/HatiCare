import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/models/lab_test_model.dart';
import 'package:haticare/features/doctor/models/prescription_model.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/appointment_detailVM.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final AppointmentDetailvm appointmentDetailvm;

  const CreatePrescriptionScreen({
    super.key,
    required this.appointmentDetailvm,
  });

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
      "quantity": TextEditingController(),
      "note": TextEditingController(),
    },
  ];

  late List<LabTest> labTests = [];
  List<int> selectedLabTestIds = [];
  bool _sendingRx = false;

  void _addAnotherMedicine() {
    final newMed = {
      "name": TextEditingController(),
      "dose": TextEditingController(),
      "freq": TextEditingController(),
      "duration": TextEditingController(),
      "quantity": TextEditingController(),
      "note": TextEditingController(),
    };

    newMed.forEach((key, controller) {
      controller.addListener(() => setState(() {}));
    });

    setState(() {
      medicines.add(newMed);
    });
  }

  bool canIssuePrescription() {
    for (var med in medicines) {
      for (var controller in med.values) {
        if (controller.text.trim().isEmpty) {
          return false;
        }
      }
    }
    return medicines.isNotEmpty;
  }

  List<DoctorMedication> getMedicationsFromControllers() {
    return medicines.map((med) {
      final quantityText = med['quantity']?.text ?? '0';
      final quantity = int.tryParse(quantityText) ?? 0;

      return DoctorMedication(
        name: med['name']?.text ?? '',
        dose: med['dose']?.text ?? '',
        frequency: med['freq']?.text ?? '',
        duration: med['duration']?.text ?? '',
        quantity: quantity,
        notes: med['note']?.text ?? '',
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    labTests = [];
    _loadLabTests();

    for (var med in medicines) {
      med.forEach((key, controller) {
        controller.addListener(() => setState(() {}));
      });
    }
  }

  Future<void> _loadLabTests() async {
    await widget.appointmentDetailvm.getLaboratoryTests();

    if (!mounted) return;

    setState(() {
      labTests = widget.appointmentDetailvm.labTests;
    });

    debugPrint('Lab tests loaded: ${labTests.map((e) => e.name).toList()}');
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
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Please fill in the details of the medicine.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 18),

                    for (int i = 0; i < medicines.length; i++) ...[
                      Row(
                        children: [
                          Text(
                            "Med ${i + 1}:",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          if (medicines.length >1)
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    medicines.removeAt(i);
                                  });
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
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

                      Row(
                        children: [
                          Expanded(
                            child: _input(
                              "Quantity",
                              medicines[i]["quantity"]!,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      _multiInput("Notes", medicines[i]["note"]!),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        // ✅ Lab Test Button
                        Expanded(
                          child: GestureDetector(
                            onTap: _openLabTestDialog,
                            child: Container(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      getSelectedLabTestLabel(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ✅ Add Another Button
                        Expanded(
                          child: Container(
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
                              label: const Text(
                                "Add Another",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                foregroundColor: Colors.black,
                              ),
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

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                    onPressed: !_sendingRx && canIssuePrescription()
                        ? () async {
                            setState(() => _sendingRx = true);

                            final meds = getMedicationsFromControllers();
                            final response = await widget.appointmentDetailvm
                                .createPrescription(
                                  medications: meds,
                                  notes:
                                      "What should I do with Appointmentdetail Notes Field.",
                                  selectedLabTests: selectedLabTestIds,
                                );

                            if (!mounted) return;

                            setState(() => _sendingRx = false);

                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  response['success'] == true
                                      ? 'Success'
                                      : 'Error',
                                ),
                                content: Text(response['message']),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) => DoctorHomeScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: _sendingRx
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Issue Rx"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLabTestDialog() {
    final tempSelected = List<int>.from(selectedLabTestIds);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Laboratory Tests'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: labTests.isEmpty
                    ? const Center(child: Text('No tests found'))
                    : ListView.builder(
                        itemCount: labTests.length,
                        itemBuilder: (context, index) {
                          final test = labTests[index];
                          return CheckboxListTile(
                            title: Text(
                              test.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: tempSelected.contains(test.id),
                            onChanged: (checked) {
                              setStateDialog(() {
                                if (checked == true) {
                                  tempSelected.add(test.id);
                                } else {
                                  tempSelected.remove(test.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedLabTestIds = tempSelected;
                });
                debugPrint("selected Lab Test IDs: $selectedLabTestIds");
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String getSelectedLabTestLabel() {
    if (selectedLabTestIds.isEmpty) {
      return 'Laboratory Test';
    }

    final firstId = selectedLabTestIds.first;

    final test = labTests.firstWhere(
      (e) => e.id == firstId,
      orElse: () => LabTest(id: 0, name: ''),
    );

    return test.name.isNotEmpty ? test.name : 'Laboratory Test';
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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
            keyboardType: keyboardType,
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
