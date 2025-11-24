// import 'package:haticare/features/doctor/models/updated_doctor_model.dart';
// import 'package:flutter/material.dart';

// class DoctorProvider extends ChangeNotifier {
//   Doctor? _doctor;

//   Doctor? get doctor => _doctor;

//   void setDoctor(Doctor doctor) {
//     _doctor = doctor;
//     notifyListeners();
//   }

//   void updateDoctor() {
//     if (_doctor != null) {
//       _doctor = Doctor(
//         firstName: _doctor!.firstName,
//         lastName: _doctor!.lastName,
//         email: _doctor!.email,
//         phoneNumber: _doctor!.phoneNumber,
//         licenseNumber: _doctor!.licenseNumber,
//         licenseType: _doctor!.licenseType,
//         specialization: _doctor!.specialization,
//         yearsOfExperience: _doctor!.yearsOfExperience,
//         licenseIssuingAuthority: _doctor!.licenseIssuingAuthority,
//         gender: _doctor!.gender,
//         dob: _doctor!.dob,
//         profilePicture: _doctor!.profilePicture
//       );
//       notifyListeners();
//     }
//   }
// }
