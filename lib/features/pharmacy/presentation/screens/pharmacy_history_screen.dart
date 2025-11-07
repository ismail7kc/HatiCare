import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_history_detail_screen.dart';
import 'package:intl/intl.dart';

class PharmacyHistoryScreen extends StatefulWidget {
  const PharmacyHistoryScreen({super.key});

  @override
  State<PharmacyHistoryScreen> createState() => _PharmacyHistoryScreenState();
}

class _PharmacyHistoryScreenState extends State<PharmacyHistoryScreen> {
  late List<PrescriptionRequest> historyItems;

  @override
  void initState() {
    super.initState();
    historyItems = PrescriptionRequest.getDummyHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          final item = historyItems[index];
          return _buildHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildHistoryCard(PrescriptionRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 0), // shadow on all sides
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PharmacyHistoryDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with gradient
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8), // adjust padding if needed
                  child: SvgPicture.asset(
                    'assets/icons/person_card_icon.svg',
                    color: Colors.white, // tint color
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.patientName}, ${request.patientAge}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(request.dateIssued)} • ${request.rxCode}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(request.status),
                  ],
                ),
              ),
              // Arrow icon
              SvgPicture.asset(
                'assets/icons/arrow_forward_icon.svg',
                width: 26,
                height: 26,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PrescriptionStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case PrescriptionStatus.notAvailable:
        backgroundColor = const Color(0xFFFAE3E3);
        textColor = const Color(0xFF8D2822);
        text = 'Not Available';
        break;
      case PrescriptionStatus.fullyDispensed:
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CA054);
        text = 'Fully Dispensed';
        break;
      case PrescriptionStatus.partiallyDispensed:
        backgroundColor = const Color(0xFFFFF1DA);
        textColor = const Color(0xFFF2B544);
        text = 'Partially Dispensed';
        break;
      case PrescriptionStatus.issued:
        backgroundColor = AppColors.primaryLight.withOpacity(0.1);
        textColor = AppColors.primaryDark;
        text = 'Issued';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
