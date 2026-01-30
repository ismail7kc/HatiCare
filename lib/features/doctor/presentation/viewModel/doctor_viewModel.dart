import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haticare/core/services/device_id_provider.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class DoctorViewModel extends ChangeNotifier {
  final RepositoryLayer repository;

  DoctorViewModel(this.repository);

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool logoutSuccess = false;

  // bool isOnline = false;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _isQueueLoading = false;
  bool get isQueueLoading => _isQueueLoading;

  // socket propetties
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  final bool _isDisposed = false;

  Timer? _queueTimer;

  init() {
    fetchPatientQueue();
    webSocketConnectionApi();
  }

  // void updateOnlineStatus(bool value) {
  //   isOnline = value;
  //   notifyListeners();
  // }

  Future<void> isDoctorOnline({required bool isOnline}) async {
    final body = {'is_online': isOnline};

    final response = await repository.updateDoctorInfo(body);
    if (response['success'] == true && response['data'] != null) {
      debugPrint(
        'Response when doctor sent online true: ${response['message']}',
      );
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
        _appointments =
            data.map((json) => AppointmentModel.fromJson(json)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint('Patient Response Data');
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
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;

    _isQueueLoading = true;
    notifyListeners();

    final response = await repository.getSingleDoctor();
    final specializationName = response['data']?['specialization'] ?? 'Unknown';

    final socketUrl =
        'wss://api.haticare.com/ws/doctor/queue/?specialization=$specializationName';

    debugPrint("WebSocket URL: $socketUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

      _channel!.stream.listen(
        (message) {
          if (_isDisposed) return;

          debugPrint("WS RAW: $message");

          try {
            final decoded = jsonDecode(message);

            if (decoded['success'] != true || decoded['data'] == null) return;

            final List<dynamic> patients = decoded['data'];
            final type = decoded['type'] ?? '';

            _isQueueLoading = false;

            for (final item in patients) {
              final int visitId = item['id'];
              _appointments.removeWhere((e) => e.id == visitId);

              switch (type) {
                case 'initial_queue':
                  debugPrint("Adding initial_queue patient");
                  final patient = AppointmentModel.fromJson(item);
                  patient.resetTimer();
                  _appointments.insert(0, patient);
                  notifyListeners();
                  break;

                case 'relisted_patient':
                  debugPrint("Adding relisted_patient immediately");

                  final patient = AppointmentModel.fromJson(item);
                  patient.resetTimer();
                  _appointments.add(patient);

                  notifyListeners();

                  _startQueueTimer();
                  break;

                case 'new_patient':
                  debugPrint("Adding new_patient");
                  final patient = AppointmentModel.fromJson(item);
                  patient.resetTimer();
                  _appointments.add(patient);
                  notifyListeners();
                  break;

                default:
                  debugPrint("Unknown queue type: $type");
              }
            }
            _startQueueTimer();
            _updateTimersInstantly();

            notifyListeners();
          } catch (e) {
            debugPrint("WS parse error: $e");
          }
        },
        onError: (_) => _reconnect(),
        onDone: _reconnect,
      );
    } catch (e) {
      debugPrint("WS connect error: $e");
      _reconnect();
    }
  }

  void _updateTimersInstantly() {
    for (final appt in _appointments) {
      if (appt.timerStartTime == null) continue;

      final elapsed = DateTime.now().difference(appt.timerStartTime!).inSeconds;

      final remaining = (30 - elapsed).clamp(0, 30);

      appt.remainingSeconds = remaining;
      appt.progress = remaining / 30;
    }
  }

  void _startQueueTimer() {
    if (_queueTimer != null) return;

    _queueTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_appointments.isEmpty) {
        _queueTimer?.cancel();
        _queueTimer = null;
        return;
      }

      bool shouldNotify = false;

      for (final appt in _appointments) {
        if (appt.timerStartTime == null) continue;

        final elapsed = DateTime.now()
            .difference(appt.timerStartTime!)
            .inSeconds;

        final remaining = (30 - elapsed).clamp(0, 30);

        if (appt.remainingSeconds != remaining) {
          appt.remainingSeconds = remaining;
          appt.progress = remaining / 30;
          shouldNotify = true;
        }
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
      return false;
    } finally {
      notifyListeners();
    }
  }
}
