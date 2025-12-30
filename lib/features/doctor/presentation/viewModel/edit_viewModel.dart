import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haticare/features/doctor/models/updated_doctor_model.dart';
import 'package:intl/intl.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';

class EditViewmodel extends ChangeNotifier {
  final RepositoryLayer repositoryLayer;

  EditViewmodel(this.repositoryLayer);

  List<Map<String, dynamic>> specializationList = [];
  List<String> specializationNames = [];

  Doctor? doctorInstance;

  Future<void> fetchSpecialization() async {
    try {
      debugPrint('===== Fetching Specializations =====');
      final response = await repositoryLayer.getSpecialization();
      debugPrint('Specialization Response: $response');

      specializationList = List<Map<String, dynamic>>.from(response['data']);
      specializationNames = specializationList
          .map((item) => item['name'] as String)
          .toList();

      debugPrint('Loaded ${specializationNames.length} specializations: $specializationNames');
      notifyListeners();
    } catch (error) {
      debugPrint('Error Fetching Specialization: $error');
      specializationNames = []; // Ensure it's empty on error
      notifyListeners();
    }
  }

  void updateDoctorInstanceFromControllers({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? licenseNumber,
    String? licenseType,
    String? specialization,
    String? yearsExperience,
    String? licenseAuthority,
    String? gender,
    DateTime? dob,
  }) {
    doctorInstance = Doctor(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      licenseNumber: licenseNumber,
      licenseType: licenseType ?? "",
      specialization: specialization ?? "",
      yearsOfExperience: int.tryParse(yearsExperience!) ?? 0,
      licenseIssuingAuthority: licenseAuthority,
      gender: gender,
      dob: dob,
    );
  }

  Future<Map<String, dynamic>> updateDoctorInfo() async {
    final body = <String, dynamic>{};

    void addIfValid(String key, dynamic value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        body[key] = value;
      }
    }

    addIfValid('first_name', doctorInstance?.firstName);
    addIfValid('last_name', doctorInstance?.lastName);
    addIfValid('user_email', doctorInstance?.email);
    addIfValid('phone_number', doctorInstance?.phoneNumber);
    addIfValid('license_number', doctorInstance?.licenseNumber);
    addIfValid('license_type', doctorInstance?.licenseType);
    addIfValid('specialization', doctorInstance?.specialization);
    addIfValid('years_of_experience', doctorInstance?.yearsOfExperience);
    addIfValid(
      'license_issuing_authority',
      doctorInstance?.licenseIssuingAuthority,
    );

    if (doctorInstance?.gender != null) {
      body['gender'] = doctorInstance!.gender == "Male"
          ? "M"
          : doctorInstance!.gender == "Female"
          ? "F"
          : "O";
    }

    if (doctorInstance?.dob != null) {
      body['date_of_birth'] = DateFormat(
        'yyyy-MM-dd',
      ).format(doctorInstance!.dob!);
    }

    final safeBody = sanitizeForJson(body);

    debugPrint('Doctor update body: $safeBody');
    final response = await repositoryLayer.updateDoctorInfo(safeBody);

    if (response['success'] == true && response['data'] != null) {
      debugPrint('Creating Doctor from JSON: ${response['data']}');
      try {
        doctorInstance = Doctor.fromJson(response['data']);
        debugPrint('Doctor instance created successfully');
        // await SaveDoctorResponse.saveDoctorModel(response['data']);
        notifyListeners();
      } catch (e) {
        debugPrint('Error creating Doctor from JSON: $e');
        debugPrint('Response data: ${response['data']}');
        rethrow;
      }
    }

    return response;
  }

  Map<String, dynamic> sanitizeForJson(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};

    data.forEach((key, value) {
      debugPrint('Processing field: $key = $value (${value.runtimeType})');
      
      if (value == null) {
        debugPrint('Skipping null field: $key');
        return;
      }

      if (value is String && value.trim().isEmpty) {
        debugPrint('Skipping empty string field: $key');
        return;
      }

      if (value is DateTime) {
        result[key] = DateFormat('yyyy-MM-dd').format(value);
        debugPrint('Added date field: $key = ${result[key]}');
      } else if (value is int || value is double || value is bool) {
        result[key] = value;
        debugPrint('Added numeric field: $key = $value');
      } else {
        result[key] = value.toString().trim();
        debugPrint('Added string field: $key = ${result[key]}');
      }
    });

    debugPrint('Final sanitized body: $result');
    return result;
  }

  Future<Map<String, dynamic>> sendProfileImageToServr(File image) async {
    final response = await repositoryLayer.sendProfileImageToServer(image);
    debugPrint('📥 ViewModel Response: $response');
    return response;
  }

  Future<Map<String, dynamic>> getSignleDocResponse() async {
    final response = await repositoryLayer.getSingleDoctor();
     debugPrint('📥 ViewModel Single Doctor Response: $response');
     doctorInstance = Doctor.fromJson(response['data']);
     
    return response;
  }
}
