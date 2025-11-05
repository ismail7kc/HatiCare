import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdProvider {
  DeviceIdProvider({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static const _storageKey = 'device_id';

  final DeviceInfoPlugin _deviceInfo;

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getString(_storageKey);
    if (cachedId != null && cachedId.isNotEmpty) {
      return cachedId;
    }

    String? deviceId;

    try {
      if (kIsWeb) {
        deviceId = null;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId;
      }
    } catch (_) {
      deviceId = null;
    }

    deviceId ??= _generateRandomId();
    await prefs.setString(_storageKey, deviceId);
    return deviceId;
  }

  String _generateRandomId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }
}
