import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/models/prescription_model.dart';

class RepositoryLayer {
  final ApiClient _apiClient;

  RepositoryLayer(this._apiClient);
  String? doctorID;

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

  Future<Map<String, dynamic>> updateDoctorInfo(
    Map<String, dynamic> body,
  ) async {
    final docID = SaveLoginResponse.loginData?['id'] ?? '';
    final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
    debugPrint('updated Doctor URL Is $url');
    return await _apiClient.updateDocRequest(url, body: body);
  }

  Future<Map<String, dynamic>> getPatientQueue() async {
    final url = '${AppConfig.baseUrl}patient/queue/';
    return await _apiClient.getPatientQueue(url);
  }

  Future<Map<String, dynamic>> createPrescription({
    required int visitId,
    required List<DoctorMedication> medications,
    String? notes,
  }) async {
    final url = '${AppConfig.baseUrl}prescriptions/';

    final Map<String, dynamic> data = {
      "visit_id": visitId,
      "medications": medications.map((m) => m.toJson()).toList(),
      "notes": notes ?? "",
    };

    debugPrint('prescription data is $data');

    return await _apiClient.createPrescription(url, body: data);
  }

  Future<Map<String, dynamic>> patientAcceptResponse(int doctorID) async {
    debugPrint('Doctor Id is here $doctorID');
    final url = '${AppConfig.baseUrl}patient/visits/$doctorID/accept/';
    return await _apiClient.acceptPatientResponse(url);
  }

  // Future<Map<String, dynamic>> getSingleDoctor() async {
  //   final docID = SaveLoginResponse.loginData?['id'] ?? '';
  //   final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
  //   return await _apiClient.getSingleDoctor(url);
  // }
}
