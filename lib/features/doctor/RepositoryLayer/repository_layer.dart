import 'dart:io';

import 'package:flutter/material.dart';
import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';

class RepositoryLayer {
  final ApiClient _apiClient;

  RepositoryLayer(this._apiClient);

  Future<Map<String, dynamic>> logout(String deviceId, String? refresh) async {
    final url = '${AppConfig.baseUrl}users/logout/';
    return await _apiClient.postRequest(
      url,
      body: {'device_id': deviceId, 'refresh': refresh},
    );
  }

  Future<Map<String, dynamic>> getSpecialization() async {
    final url = '${AppConfig.baseUrl}users/specializations/';
    return await _apiClient.getRequest(url);
  }

  Future<Map<String, dynamic>> sendProfileImageToServer(File imageFile) async {
    final docID = SaveLoginResponse.loginData?['id'] ?? '';
    final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
    final response = await _apiClient.uploadProfileImage(url, imageFile);
    debugPrint("📥 Repository Response: $response");
    return response;
  }

  Future<Map<String, dynamic>> updateDoctorInfo(Map<String, dynamic> body) async {
    final docID = SaveLoginResponse.loginData?['id'] ?? '';
    final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
    return await _apiClient.updateDocRequest(url, body: body);
  }

  Future<Map<String, dynamic>> getPatientQueue() async {
    final url = '${AppConfig.baseUrl}patient/queue/'; // replace with your actual endpoint
    return await _apiClient.getPatientQueue(url);
  }

  // Future<Map<String, dynamic>> getSingleDoctor() async {
  //   final docID = SaveLoginResponse.loginData?['id'] ?? '';
  //   final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
  //   return await _apiClient.getSingleDoctor(url);
  // }
}
