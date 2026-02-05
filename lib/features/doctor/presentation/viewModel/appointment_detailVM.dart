import 'package:flutter/material.dart';
import 'package:haticare/features/common/global_alert.dart';
import 'package:haticare/features/common/repository_layer.dart';
import 'package:haticare/features/doctor/models/lab_test_model.dart';
import 'package:haticare/features/doctor/models/prescription_model.dart';

class AppointmentDetailvm extends ChangeNotifier {
  final RepositoryLayer respositoryLayer;

  AppointmentDetailvm(this.respositoryLayer);

  bool _isLoading = false;
  bool get loading => _isLoading;
  int visitId = 0;

  List<LabTest> labTests = [];

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
      } else {
        GlobalAlert.show(response['message']);
      }
    } catch (error) {
      debugPrint('Accept Patient error: $error');
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getLaboratoryTests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await respositoryLayer.getLabTests();

      if (response['success'] == true && response['data'] != null) {
        labTests = (response['data'] as List)
            .map((e) => LabTest.fromJson(e))
            .toList();
      } else {
        GlobalAlert.show(response['message']);
      }
    } catch (error) {
      debugPrint('Laboratory Test Error: $error');
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPrescription({
    required List<DoctorMedication> medications,
    String? notes,
    required List<int> selectedLabTests,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('Selected Lab Tests is $selectedLabTests');
      final response = await respositoryLayer.createPrescription(
        visitId: visitId,
        medications: medications,
        notes: notes,
        selectedLabTests: selectedLabTests,
      );

      if (response['success'] != true) {
        GlobalAlert.show(response['message']);
      }

      return response;
    } catch (error) {
      _errorMessage = error.toString();
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> doctorCompleteVisit(String notes) async {
    try {
      final response = await respositoryLayer.futureVisitCompleted(
        visitId,
        notes,
      );

      if (response['success'] != true) {
        GlobalAlert.show(response['message'] ?? 'Failed to complete visit');
      }

      return response;
    } catch (error) {
      return {"success": false, "message": "Something went wrong: $error"};
    }
  }
}
