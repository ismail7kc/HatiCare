import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
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
      final response = await repositoryLayer.getSpecialization();
      specializationList = List<Map<String, dynamic>>.from(response['data']);
      specializationNames = specializationList
          .map((item) => item['name'] as String)
          .toList();

      notifyListeners();
    } catch (error) {
      debugPrint('Error Fetching Specialization: $error');
    }
  }

  void updateDoctorInstanceFromControllers({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String licenseNumber,
    required String? licenseType,
    required String? specialization,
    required String yearsExperience,
    required String licenseAuthority,
    required String gender,
    required DateTime? dob,
  }) {
    doctorInstance = Doctor(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      licenseNumber: licenseNumber,
      licenseType: licenseType ?? "",
      specialization: specialization ?? "",
      yearsOfExperience: int.tryParse(yearsExperience) ?? 0,
      licenseIssuingAuthority: licenseAuthority,
      gender: gender,
      dob: dob,
    );
  }

  Future<Map<String, dynamic>> updateDoctorInfo() async {
    final body = {
      'first_name': doctorInstance?.firstName ?? '',
      'last_name': doctorInstance?.lastName ?? '',
      'user_email': doctorInstance?.email ?? '',
      'phone_number': doctorInstance?.phoneNumber ?? '',
      'license_number': doctorInstance?.licenseNumber ?? '',
      'license_type': doctorInstance?.licenseType ?? '',
      'specialization': doctorInstance?.specialization ?? '',
      'years_of_experience': doctorInstance?.yearsOfExperience ?? '',
      'license_issuing_authority':
          doctorInstance?.licenseIssuingAuthority ?? '',
      'gender': doctorInstance?.gender == "Male"
          ? "M"
          : doctorInstance?.gender == "Female"
          ? "F"
          : "O",
      'date_of_birth': doctorInstance?.dob != null
          ? DateFormat('yyyy-MM-dd').format(doctorInstance!.dob!)
          : null,
    };

    final response = await repositoryLayer.updateDoctorInfo(body);

    if (response['success'] == true && response['data'] != null) {
      doctorInstance = Doctor.fromJson(response['data']);
      await SaveDoctorResponse.saveDoctorModel(response['data']);

      print(doctorInstance);

      notifyListeners();
    }

    return response;
  }

  Future<Map<String, dynamic>> sendProfileImageToServr(File image) async {
    final response = await repositoryLayer.sendProfileImageToServer(image);
    debugPrint('📥 ViewModel Response: $response');
    return response;
  }
}
