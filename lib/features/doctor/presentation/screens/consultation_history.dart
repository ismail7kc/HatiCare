import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/presentation/screens/history_detail.dart';
import 'package:haticare/features/doctor/presentation/viewModel/patient_history_VM.dart';
import 'package:provider/provider.dart';

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  State<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PatientHistoryVm>().fetchPatientHistory();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<PatientHistoryVm>().fetchPatientHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
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
                child: Consumer<PatientHistoryVm>(
                  builder: (context, vm, _) {
                    if (vm.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (vm.errorMessage != null) {
                      return Center(
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (vm.history.isEmpty) {
                      return const Center(child: Text("No history found"));
                    }

                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: AppColors.primary,
                      child: ListView.builder(
                        itemCount: vm.history.length,
                        physics: const AlwaysScrollableScrollPhysics(),

                        itemBuilder: (context, index) {
                          final history = vm.history[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () => {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HistoryDetail(visit: history),
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
                                      color: Colors.black12.withValues(
                                        alpha: 0.05,
                                      ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${history.patientName}, ${history.patient.age}",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${history.createdAt.day.toString().padLeft(2, '0')}/"
                                            "${history.createdAt.month.toString().padLeft(2, '0')}/"
                                            "${history.createdAt.year} "
                                            "${history.createdAt.hour.toString().padLeft(2, '0')}:"
                                            "${history.createdAt.minute.toString().padLeft(2, '0')}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .medical_information_outlined,
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
