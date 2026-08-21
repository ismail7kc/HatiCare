import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/api_client.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/audio_call.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/screens/issue_rx.dart';
import 'package:haticare/features/doctor/presentation/viewModel/appointment_detailVM.dart';
import 'package:haticare/features/doctor/presentation/viewModel/audio_callVM.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:provider/provider.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final bool isCameFromAccept;
  final int? visitId;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.isCameFromAccept = false,
    this.visitId,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailState();
}

class _AppointmentDetailState extends State<AppointmentDetailScreen> {
  late AppointmentDetailvm appointmentDetailvm;
  final symptoms = ["Fever", "Headache", "Cough", "flu"];
  bool _accepting = false;

  final TextEditingController notesController = TextEditingController();
  bool isNotesFilled = false;
  bool _isCompleting = false; // loading indicator for complete button

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    final repository = RepositoryLayer(apiClient);
    appointmentDetailvm = AppointmentDetailvm(repository);

    if (widget.visitId != null) {
      appointmentDetailvm.visitId = widget.visitId!;
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Appointment Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: !widget.isCameFromAccept
            ? [
                IconButton(
                  icon: _isCompleting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.check,
                          color: isNotesFilled ? Colors.green : Colors.grey,
                        ),
                  onPressed: isNotesFilled && !_isCompleting
                      ? () async {
                          setState(() => _isCompleting = true);

                          final notesText = notesController.text.trim();

                          final response = await appointmentDetailvm
                              .doctorCompleteVisit(notesText);

                          if (!mounted) return;

                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                response["success"] == true
                                    ? "Success"
                                    : "Error",
                              ),
                              content: Text(response["message"] ?? ""),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );

                          setState(() => _isCompleting = false);

                          if (response["success"] == true) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const DoctorHomeScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      : null,
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.isCameFromAccept) ...[
              const Text(
                "Incoming Request",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                "You have 19 seconds to respond",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),
            ],
            if (widget.isCameFromAccept) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade50,
                    child: SvgPicture.asset(
                      'assets/icons/user-square.svg',
                      height: 36,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ] else ...[
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade50,
                child: SvgPicture.asset(
                  'assets/icons/person_Img.svg',
                  height: 100,
                  width: 100,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              widget.appointment.patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icons/sticky-note.svg', height: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          title: 'Primary Concern',
                          value: widget.appointment.primaryConcern,
                        ),

                        const SizedBox(height: 10),

                        _buildInfoRow(
                          title: 'Risk Level',
                          value: widget.appointment.riskLevelText,
                        ),

                        const SizedBox(height: 10),

                        _buildInfoRow(
                          title: 'Specialization',
                          value:
                              widget
                                  .appointment
                                  .triageData
                                  .primarySpecializationName
                                  .isNotEmpty
                              ? widget
                                    .appointment
                                    .triageData
                                    .primarySpecializationName
                              : 'Not Available',
                        ),

                        if (widget.appointment.winningScore != null) ...[
                          const SizedBox(height: 10),

                          _buildInfoRow(
                            title: 'Risk Score',
                            value: '${widget.appointment.winningScore}',
                          ),
                        ],

                        const SizedBox(height: 10),

                        _buildInfoRow(
                          title: 'Patient Status',
                          value: widget.appointment.status.isNotEmpty
                              ? widget.appointment.status
                              : 'Pending',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/sticky-note.svg',
                        height: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Reported Symptoms",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.appointment.reportedSymptoms.map((symptom) {
                      return Chip(
                        label: Text(
                          symptom,
                          style: const TextStyle(
                            color: Color(0xFF8B0000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: const Color(0xFFFFE5E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!widget.isCameFromAccept) ...[
              Container(
                height: 108,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/icons//sticky-note.svg',
                      height: 22,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextField(
                          controller: notesController,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (value) {
                            setState(() {
                              isNotesFilled = value.trim().isNotEmpty;
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Notes',
                            hintStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            contentPadding: EdgeInsets.only(top: -30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    'assets/icons/video_2.svg',
                    "Issue RX",
                  ),
                  _buildActionButton(
                    context,
                    'assets/icons/video_1.svg',
                    "Referral",
                  ),
                  _buildActionButton(
                    context,
                    'assets/icons/video_3.svg',
                    "Hospitalize",
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            if (widget.isCameFromAccept) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: _accepting
                            ? null
                            : () async {
                                setState(() => _accepting = true);

                                final micGranted = await requestMicPermission();

                                if (!micGranted) {
                                  setState(() => _accepting = false);

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Microphone permission is required to start call',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await appointmentDetailvm.acceptPatientResponse(
                                  widget.appointment.id,
                                );

                                final visitId = appointmentDetailvm.visitId;

                                setState(() => _accepting = false);

                                if (!mounted) return;

                                if (visitId == 0) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Error'),
                                      content: Text(
                                        appointmentDetailvm.errorMessage,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                PersistentNavBarNavigator.pushNewScreen(
                                  context,
                                  screen: ChangeNotifierProvider(
                                    create: (_) => AudioCallVM(),
                                    child: AudioCallScreen(
                                      appointments: widget.appointment,
                                      visitId: visitId,
                                    ),
                                  ),
                                  withNavBar: false,
                                  pageTransitionAnimation:
                                      PageTransitionAnimation.cupertino,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _accepting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Accept & Call",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              if (valueColor != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: valueColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String iconPath,
    String label,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePrescriptionScreen(
                  appointmentDetailvm: appointmentDetailvm,
                ),
              ),
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: SvgPicture.asset(iconPath, width: 80, height: 64),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
