import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haticare/features/pharmacy/models/prescription_request.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_history_detail_screen.dart';
import 'package:haticare/features/pharmacy/presentation/widgets/pharmacy_history_card.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';

class PharmacyHistoryScreen extends StatefulWidget {
  const PharmacyHistoryScreen({super.key});

  @override
  State<PharmacyHistoryScreen> createState() => _PharmacyHistoryScreenState();
}

class _PharmacyHistoryScreenState extends State<PharmacyHistoryScreen> {
  List<PrescriptionRequest> historyItems = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
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

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/history/');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        
        List<dynamic> prescriptionsList = [];
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('results') && 
              jsonResponse['results'] is Map<String, dynamic> &&
              jsonResponse['results'].containsKey('data') && 
              jsonResponse['results']['data'] is List) {
            prescriptionsList = jsonResponse['results']['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            prescriptionsList = jsonResponse['data'] as List<dynamic>;
          }
        } else if (jsonResponse is List) {
          prescriptionsList = jsonResponse as List<dynamic>;
        }

        setState(() {
          historyItems = prescriptionsList.map((item) {
            return PrescriptionRequest.fromJson(item as Map<String, dynamic>);
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load history: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading history: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchHistory();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('History refreshed successfully'),
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
          'History',
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
                onPressed: _fetchHistory,
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

    if (historyItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No history found',
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
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        final item = historyItems[index];
        return PharmacyHistoryCard(
          request: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PharmacyHistoryDetailScreen(request: item),
              ),
            );
          },
        );
      },
    );
  }
}
