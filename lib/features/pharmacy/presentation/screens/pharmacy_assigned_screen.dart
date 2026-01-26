import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';

class PharmacyAssignedScreen extends StatefulWidget {
  const PharmacyAssignedScreen({super.key});

  @override
  State<PharmacyAssignedScreen> createState() => _PharmacyAssignedScreenState();
}

class _PharmacyAssignedScreenState extends State<PharmacyAssignedScreen> {
  List<AssignedPrescription> assignedItems = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssigned();
  }

  Future<void> _fetchAssigned() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        setState(() {
          errorMessage = 'No authentication token found';
          isLoading = false;
        });
        return;
      }

      final uri =
          Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/assigned/');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        List<dynamic> rawList = [];

        if (jsonResponse is Map<String, dynamic>) {
          final results = jsonResponse['results'];
          if (results is Map<String, dynamic> && results['data'] is List) {
            rawList = results['data'] as List<dynamic>;
          }
        } else if (jsonResponse is List) {
          rawList = jsonResponse;
        }

        setState(() {
          assignedItems = rawList
              .whereType<Map<String, dynamic>>()
              .map(AssignedPrescription.fromJson)
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load assigned prescriptions: '
              '${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading assigned prescriptions: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchAssigned();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Assigned prescriptions refreshed'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assigned',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAssigned,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (assignedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No assigned prescriptions yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: assignedItems.length,
      itemBuilder: (context, index) {
        final item = assignedItems[index];
        return _AssignedPrescriptionCard(item: item);
      },
    );
  }
}

class AssignedPrescription {
  final String id;
  final String rxCode;
  final String patientName;
  final String patientPhone;
  final String pharmacyStatus;
  final String availability;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime? completedAt;

  AssignedPrescription({
    required this.id,
    required this.rxCode,
    required this.patientName,
    required this.patientPhone,
    required this.pharmacyStatus,
    required this.availability,
    required this.isVerified,
    required this.verifiedAt,
    required this.completedAt,
  });

  factory AssignedPrescription.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return AssignedPrescription(
      id: json['prescription_id']?.toString() ?? '',
      rxCode: json['rex_code']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Unknown Patient',
      patientPhone: json['patient_phone']?.toString() ?? '-',
      pharmacyStatus: json['pharmacy_status']?.toString() ?? 'assigned',
      availability: json['availability']?.toString() ?? 'pending',
      isVerified: json['is_verified'] == true,
      verifiedAt: tryParse(json['verified_at']?.toString()),
      completedAt: tryParse(json['completed_at']?.toString()),
    );
  }
}

class _AssignedPrescriptionCard extends StatelessWidget {
  final AssignedPrescription item;

  const _AssignedPrescriptionCard({required this.item});

  Color _statusColor(BuildContext context) {
    if (item.isVerified) return Colors.green;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.rxCode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.pharmacyStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.patientPhone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Availability: ${item.availability.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (item.isVerified || item.verifiedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Verified'
                  '${item.verifiedAt != null ? ' · ${_formatDate(item.verifiedAt!)}' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }
}
