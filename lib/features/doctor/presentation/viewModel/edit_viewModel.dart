import 'package:flutter/material.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';

class EditViewmodel extends ChangeNotifier {
  final RepositoryLayer _repositoryLayer;

  EditViewmodel(this._repositoryLayer);

  List<Map<String, dynamic>> specializationList = [];
  List<String> specializationNames = [];

  String firstName = '';
  String lastName = '';
  String email = '';
  String phoneNumber = '';
  String? licenseNumber = '';
  String licenseType = '';
  String specialization = '';
  String? yearsOfExperience = '';
  String? licenseIssuingAuthority = '';
  String gender = '';
  DateTime? dob;

  Future<void> fetchSpecialization() async {
    try {
      final response = await _repositoryLayer.getSpecialization();
      specializationList = List<Map<String, dynamic>>.from(response['data']);
      specializationNames = specializationList
          .map((item) => item['name'] as String)
          .toList();

      debugPrint('specialization is: $specializationList');
      notifyListeners();
    } catch (error) {
      debugPrint('Error Fetching Specialization: $error');
    }
  }

  Future<void> updateDoctorInfo() async {
    try {
      final body = {
        'first_name': firstName,
        'last_name': lastName,
        'user_email': email,
        'phone_number': phoneNumber,
        'license_number': licenseNumber,
        'license_type': licenseType,
        'specialization': specialization,
        'years_of_experience': yearsOfExperience,
        'license_issuing_authority': licenseIssuingAuthority,
        'gender': gender,
        'date_of_birth': dob,
      };

      print('parameter list is here: $body');

      final response = await _repositoryLayer.updateDoctorInfo(body);
      debugPrint('Doctor info updated: $response');
    } catch (e) {
      debugPrint('Error updating doctor info: $e');
    }
  }
}
