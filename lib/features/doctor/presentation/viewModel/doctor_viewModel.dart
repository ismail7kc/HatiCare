import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haticare/core/services/device_id_provider.dart';
import 'package:haticare/features/common/global_alert.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorViewModel extends ChangeNotifier {
  final RepositoryLayer repository;

  DoctorViewModel(this.repository);

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool logoutSuccess = false;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _isQueueLoading = false;
  bool get isQueueLoading => _isQueueLoading;

  bool isOnline = false;

  // socket propetties
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  bool _isDisposed = false;

  Timer? _queueTimer;

  init() {
    fetchPatientQueue();
    webSocketConnectionApi();
    // _startQueueTimer();
  }

  Future<bool> isDoctorOnline({required bool isOnline}) async {
    try {
      final body = {'is_online': isOnline};
      final response = await repository.updateDoctorInfo(body);

      if (response['success'] == true) {
        return true;
      } else {
        GlobalAlert.show(response['message'] ?? "Failed to update status");
        return false;
      }
    } catch (error) {
      GlobalAlert.show("Something went wrong: $error");
      return false;
    }
  }

  Future<void> loadOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isOnline = prefs.getBool("doctor_online") ?? false;
    notifyListeners();
  }

  Future<void> updateOnlineStatus(bool value) async {
    isOnline = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("doctor_online", value);

    notifyListeners();
  }

  Future<void> fetchPatientQueue() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await repository.getPatientQueue();
      if (response['success'] == true && response['data'] != null) {
        final List data = response['data'] as List;
        _appointments =
            data.map((json) => AppointmentModel.fromJson(json)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        debugPrint('Patient Response Data');
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch patient queue';
        GlobalAlert.show(response['message']);
      }
    } catch (e) {
      _errorMessage = e.toString();
      GlobalAlert.show(_errorMessage);
    } finally {
      _isLoading = false;
      if (_appointments.isNotEmpty) {
        _startQueueTimer(); // ✅ ADD THIS
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _queueTimer?.cancel();
    disconnectWebSocket();
    super.dispose();
  }

  Future<void> webSocketConnectionApi() async {
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;

    _isQueueLoading = true;
    notifyListeners();

    final doctorId = SaveLoginResponse.loginData?['id'] ?? '';
    final socketUrl =
        'wss://api.haticare.com/ws/doctor/queue/?user_id=$doctorId';

    _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

    _channel!.stream.listen(
      (message) => _handleWebSocketMessage(message),
      onError: (_) => _reconnect(),
      onDone: _reconnect,
    );
  }

  void _handleWebSocketMessage(String message) {
    if (_isDisposed) return;

    try {
      final decoded = jsonDecode(message);
      if (decoded['success'] != true || decoded['data'] == null) return;

      final List<dynamic> patients = decoded['data'];
      final type = decoded['type'] ?? '';

      bool listChanged = false;

      final List<AppointmentModel> updatedAppointments = List.from(
        _appointments,
      );

      // for (final item in patients) {
      //   final int visitId = item['id'];
      //   int serverRemaining = item['remaining_seconds'] ?? 30;

      //   final index = updatedAppointments.indexWhere((e) => e.id == visitId);

      //   if (type == 'initial_queue' || type == 'new_patient') {
      //     if (index == -1) {
      //       updatedAppointments.add(AppointmentModel.fromJson(item));
      //       listChanged = true;
      //     } else {
      //       updatedAppointments[index].resetFromServer(serverRemaining);
      //       listChanged = true;
      //     }
      //   } else if (type == 'relisted_patient') {
      //     if (index == -1) {
      //       final appt = AppointmentModel.fromJson(item);
      //       appt.remainingSeconds = 29;
      //       updatedAppointments.add(appt);
      //       listChanged = true;
      //     } else {
      //       updatedAppointments[index].resetFromServer(29);
      //       listChanged = true;
      //     }
      //   }
      // }

      for (final item in patients) {
        final int visitId = item['id'];
        final int serverRemaining = item['remaining_seconds'] ?? 30;

        final index = updatedAppointments.indexWhere((e) => e.id == visitId);

        if (type == 'initial_queue' ||
            type == 'new_patient' ||
            type == 'relisted_patient') {
          if (index == -1) {
            updatedAppointments.add(AppointmentModel.fromJson(item));
            listChanged = true;
          } else {
            updatedAppointments[index].resetFromServer(serverRemaining);
            listChanged = true;
          }
        }
      }

      if (listChanged) {
        _appointments = updatedAppointments;
        notifyListeners();
      }

      if (_appointments.isNotEmpty) _startQueueTimer();
    } catch (e) {
      debugPrint("WS parse error: $e");
    }
  }

  Future<void> disconnectWebSocket() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _isConnecting = false;
      debugPrint("WebSocket Disconnected");
    }
  }

  void _startQueueTimer() {
    if (_queueTimer?.isActive ?? false) return;

    _queueTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      print('ticker');
      bool shouldNotify = false;

      for (final appt in _appointments) {
        appt.tick();
        shouldNotify = true;
      }

      if (shouldNotify) notifyListeners();
    });
  }

  void _reconnect() {
    if (_isDisposed) return;

    _isConnecting = false;
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed) webSocketConnectionApi();
    });
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

  Future<bool> logout() async {
    debugPrint(await DeviceIdProvider().getDeviceId());
    try {
      final deviceId = await DeviceIdProvider().getDeviceId();
      final token = await SharedPrefsHelper.getRefreshToken();
      final result = await repository.logout(deviceId, token);
      debugPrint('Logout Success: $result');

      logoutSuccess = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('device_id');
      await prefs.remove('user_type');
      await prefs.remove('user_email');
      await prefs.setBool('is_logged_in', false);

      SharedPrefsHelper.clearRefreshToken();

      return true;
    } catch (error) {
      debugPrint('Logout Error: $error');
      GlobalAlert.show('Logout failed: $error');
      return false;
    } finally {
      notifyListeners();
    }
  }
}
