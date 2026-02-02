import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/models/assign_prescription.dart';
import 'package:haticare/features/pharmacy/presentation/screens/assigned_detail_screen.dart';
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
  List<AssignedPrescription> filteredItems = [];
  late TextEditingController _rxCodeController;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _rxCodeController = TextEditingController();
    _fetchAssigned();
  }

  @override
  void dispose() {
    _rxCodeController.dispose();
    super.dispose();
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
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/assigned/?status=assigned'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch assigned prescriptions');
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      final List<dynamic> dataList = jsonResponse['results']?['data'] ?? [];

      setState(() {
        assignedItems = dataList
            .map((e) => AssignedPrescription.fromJson(e))
            .toList();
        filteredItems = assignedItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterPrescriptions(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredItems = assignedItems;
      });
      return;
    }

    final queryUpper = query.toUpperCase();
    setState(() {
      filteredItems = assignedItems.where((prescription) {
        final rxCode = prescription.rxCode.toUpperCase();
        return rxCode.contains(queryUpper);
      }).toList();
    });
  }

  Future<void> verifyPrescription(String rxCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) return;

      final url = Uri.parse(
        '${AppConfig.baseUrl}prescriptions/pharmacy/verify/',
      );
      final body = jsonEncode({'rex_code': rxCode.trim()});

      debugPrint('Verify API URL: $url');
      debugPrint(
        'Headers: ${{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'}}',
      );
      debugPrint('Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded['success'] == true) {
          debugPrint('Prescription verified successfully!');
          await _fetchAssigned();
        } else {
          debugPrint('Verify failed: ${decoded['message']}');
        }
      } else {
        debugPrint('Verify failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error verifying prescription: $e');
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Search Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Prescription',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rxCodeController,
                            textCapitalization: TextCapitalization.characters,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(8),
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Z0-9]'),
                              ),
                            ],
                            onChanged: (value) {
                              // Convert to uppercase
                              if (value != value.toUpperCase()) {
                                _rxCodeController.text = value.toUpperCase();
                                _rxCodeController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: value.length),
                                );
                              }
                              // Trigger filtering
                              _filterPrescriptions(_rxCodeController.text);
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter Rx Code (8 chars, e.g., 599147EF)',
                              hintStyle: const TextStyle(
                                color: Color(0xFF858585),
                                fontSize: 14,
                              ),
                              suffixIcon: _rxCodeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _rxCodeController.clear();
                                        _filterPrescriptions('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryDark,
                                  width: 2,
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () {
                            verifyPrescription(_rxCodeController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Search',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
            const SizedBox(height: 4),

            // Assigned text with count
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_rxCodeController.text.isNotEmpty)
                    Text(
                      'Showing ${filteredItems.length} of ${assignedItems.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
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
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
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
                        )
                      : filteredItems.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _fetchAssigned,
                              color: AppColors.primary,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height - 300,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 64,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _rxCodeController.text.isNotEmpty
                                                ? 'No matching prescriptions'
                                                : 'No Assigned Items',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _rxCodeController.text.isNotEmpty
                                                ? 'Try a different RX code'
                                                : 'Pull down to refresh',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchAssigned,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredItems.length,
                                itemBuilder: (_, index) {
                                  final item = filteredItems[index];
                                  return AssignedPrescriptionCard(
                                    item: item,
                                    onVerify: verifyPrescription,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignedPrescriptionCard extends StatelessWidget {
  final AssignedPrescription item;
  final void Function(String rxCode) onVerify;

  const AssignedPrescriptionCard({
    super.key,
    required this.item,
    required this.onVerify,
  });

  Color _statusColor(BuildContext context) {
    return item.isVerified
        ? Colors.green
        : Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = item.isVerified;

    return InkWell(
      onTap: () async {
        if (isVerified) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignedDetailScreen(request: item),
            ),
          );
          
          // Refresh the list if prescription was completed
          if (result == true && context.mounted) {
            // Find the parent state and refresh
            final parentState = context.findAncestorStateOfType<_PharmacyAssignedScreenState>();
            parentState?._fetchAssigned();
          }
        }
      },

      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.pharmacyStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.patientPhone,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.medical_services_outlined, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  item.doctor.startsWith('Dr.') ? item.doctor : 'Dr. ${item.doctor}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Availability: ${item.availability.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isVerified)
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
                    ),
                  ),
                ],
              ),
            if (!isVerified)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton(
                    onPressed: () => onVerify(item.rxCode),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Verify'),
                  ),
                ),
              ),
          ],
        ),
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
