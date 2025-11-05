import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/presentation/screens/history_detail.dart';
import '../../models/conslutation_hitory_model.dart';

class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final consultations = ConsultationHistoryModel.sampleData;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Consultation History",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 25),

              Expanded(
                child: ListView.builder(
                  itemCount: consultations.length,
                  itemBuilder: (context, index) {
                    final history = consultations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryDetail(),
                            ),
                          ),
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 45,
                                width: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${history.patientName}, ${history.patientAge}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${history.date} • ${history.duration}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Icon(
                                          history.isPrescriptionIssued
                                              ? Icons
                                                    .medical_information_outlined
                                              : Icons.chat_outlined,
                                          color: AppColors.primaryDark,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          history.status,
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
