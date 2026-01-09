import 'package:flutter/material.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';

class DoctorViewModel extends ChangeNotifier {
  final RepositoryLayer repository;

  DoctorViewModel(this.repository);

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> isDoctorOnline({required bool isOnline}) async {
    final body = {'is_online': isOnline};
    
    // update PATCH request if doctor have patient or not
    final response = await repository.updateDoctorInfo(body);

    if (response['success'] == true && response['data'] != null) {
      debugPrint('Response when docter send online true $response[message]');
      notifyListeners();
    }
  }

  Future<void> fetchPatientQueue() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await repository.getPatientQueue();

      if (response['success'] == true && response['data'] != null) {
        final List data = response['data'] as List;
        _appointments = data
            .map((json) => AppointmentModel.fromJson(json))
            .toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch patient queue';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String formatAppointmentTime(DateTime dateTime) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final isToday = today == dateOnly;
    final isYesterday = today.subtract(const Duration(days: 1)) == dateOnly;

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? "PM" : "AM";

    final timeFormatted = "$hour:$minute $ampm";

    if (isToday) return "Today $timeFormatted";
    if (isYesterday) return "Yesterday $timeFormatted";

    return "${_month(dateTime.month)} ${dateTime.day}, $timeFormatted";
  }

  String _month(int m) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m];
  }
}
