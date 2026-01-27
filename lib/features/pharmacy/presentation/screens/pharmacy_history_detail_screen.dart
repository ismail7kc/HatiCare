import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:haticare/core/theme/app_colors.dart';

class PharmacyHistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> prescription;

  const PharmacyHistoryDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/arrow_back_icon.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prescription ID: ${prescription['prescription_id']}'),
            const SizedBox(height: 8),
            Text('Patient: ${prescription['patient_name']}'),
            const SizedBox(height: 8),
            Text('Status: ${prescription['pharmacy_status']}'),
          ],
        ),
      ),
    );
  }
}
