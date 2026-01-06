import 'package:flutter/material.dart';
import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class DoctorViewModel extends ChangeNotifier {
  final RepositoryLayer repository;

  DoctorViewModel(this.repository);
  WebSocketChannel? _channel;

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
        debugPrint('Fetch Patient Api Triggered');
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

  Future<void> webSocketConnectionApi() async {
    final uri = Uri.parse(AppConfig.baseUrl);
    final socketUrl = 'wss://${uri.host}/ws/doctor/queue/';

    debugPrint("Base URL: ${AppConfig.baseUrl}");
    debugPrint("Parsed host: ${uri.host}");
    debugPrint("WebSocket URL: $socketUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

      _channel!.stream.listen(
        (message) {
          debugPrint("WS listen event");
          debugPrint("WS Message: $message");
          fetchPatientQueue()
              .then((_) { 
                debugPrint("fetchPatientQueue triggered");
              })
              .catchError((e) {
                debugPrint("fetchPatientQueue error: $e");
              });
        },
        onDone: () {
          debugPrint("WS Closed — reconnecting...");
          // _reconnect();
        },
        onError: (error) {
          debugPrint("WS Error — reconnecting: $error");
          // _reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint("WS connect error: $e");
      _reconnect();
    }
  }

  void _reconnect() async {
    await Future.delayed(const Duration(seconds: 3));
    await webSocketConnectionApi();
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
