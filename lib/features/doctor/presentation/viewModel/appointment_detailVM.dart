import 'package:flutter/material.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/models/prescription_model.dart';

class AppointmentDetailvm extends ChangeNotifier {
  final RepositoryLayer respositoryLayer;

  AppointmentDetailvm(this.respositoryLayer);

  bool _isLoading = false;
  bool get loading => _isLoading;
  int visitId = 0;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> acceptPatientResponse(int doctorID) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await respositoryLayer.patientAcceptResponse(doctorID);

      if (response['success'] == true && response['data'] != null) {
        visitId = response['data']['id'];
        debugPrint('visit Id is $visitId');
        debugPrint('Accept Patient Reponse Got Correctly');
      }
    } catch (error) {
      debugPrint('Accept Patient $error');
      _errorMessage = error.toString();
    }
  }

  Future<void> createPrescription({
    required List<DoctorMedication> medications,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await respositoryLayer.createPrescription(
        visitId: visitId,
        medications: medications,
        notes: notes,
      );

      if (response['success'] == true && response['data'] != null) {
        debugPrint('Create Prescription Response Got Correctly');
        debugPrint(response['message']);
      } else {
        _errorMessage = response['message'] ?? 'Unknown error';
      }
    } catch (error) {
      debugPrint('Create Prescription $error');
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
