import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/models/prescription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final dynamic rawDocId = SaveLoginResponse.loginData?['id'];
    final String docID = rawDocId?.toString() ?? '';
    final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
    final response = await _apiClient.uploadProfileImage(url, imageFile);
    debugPrint("📥 Repository Response: $response");
    return response;
  }

  Future<Map<String, dynamic>> updateDoctorInfo(
    Map<String, dynamic> body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawDocId = SaveLoginResponse.loginData?['id'];
    final String docID =
        rawDocId?.toString() ?? prefs.getString('doctor_id') ?? '';
    final accessToken =
        SaveLoginResponse.loginData?['access_token'] ??
        prefs.getString('access_token') ??
        '';
    final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
    debugPrint('updated Doctor URL Is $url');
    debugPrint('Doctor ID: $docID');
    debugPrint('Access Token exists: ${accessToken.isNotEmpty}');

    if (docID.isEmpty) {
      debugPrint('ERROR: Doctor ID is empty');
      return {'success': false, 'message': 'Doctor ID not found'};
    }

    if (accessToken.isEmpty) {
      debugPrint('ERROR: Access token is empty');
      return {'success': false, 'message': 'Access token not found'};
    }

    debugPrint('Calling updateDocRequest with URL: $url');
    debugPrint('Request body: $body');
    try {
      final response = await _apiClient.updateDocRequest(url, body: body);
      debugPrint('Repository response: $response');
      return response;
    } catch (e) {
      debugPrint('Error in repository layer: $e');
      debugPrint('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPatientQueue() async {
    final url = '${AppConfig.baseUrl}patient/queue/';
    return await _apiClient.getPatientQueue(url);
  }

  Future<Map<String, dynamic>> createPrescription({
    required int visitId,
    required List<DoctorMedication> medications,
    String? notes,
    required List<int> selectedLabTests,
  }) async {
    final url = '${AppConfig.baseUrl}prescriptions/';

    final Map<String, dynamic> data = {
      "visit_id": visitId,
      "medications": medications.map((m) => m.toJson()).toList(),
      "notes": notes ?? "",
      "lab_tests": selectedLabTests,
       
    };

    debugPrint('prescription data is $data');

    return await _apiClient.createPrescription(url, body: data);
  }

  Future<Map<String, dynamic>> patientAcceptResponse(int doctorID) async {
    debugPrint('Doctor Id is here $doctorID');
    final url = '${AppConfig.baseUrl}patient/visits/$doctorID/accept/';
    return await _apiClient.acceptPatientResponse(url);
  }

  Future<Map<String, dynamic>> getSingleDoctor() async {
    final prefs = await SharedPreferences.getInstance();

    final dynamic rawDocId = SaveLoginResponse.loginData?['id'] ?? prefs.getString('doctorId');

    if (rawDocId == null || rawDocId.toString().isEmpty) {
      throw Exception("Doctor Id not found");
    }

    final String docID = rawDocId.toString();
    final url = '${AppConfig.baseUrl}doc/doctors/$docID/';
    return await _apiClient.getSingleDoctor(url);
  }

  Future<Map<String, dynamic>> getLabTests() async {
    // if u want to fetch only Name send 'names_only' with true in query params
    // if u want fetch dropdown with id then send 'dropdown' with true in query params
    // if u want fetch entire page then send 'page=1', 'page=2' etc 

    final uri = '${AppConfig.baseUrl}lab/lab-tests/?dropdown=true';
    return await _apiClient.getLabTestFromServer(uri);
  }
}
