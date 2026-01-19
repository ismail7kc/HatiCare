import 'package:flutter/material.dart';
import 'package:haticare/features/doctor/models/patient_visit_history.dart';

import '../../../common/repository_layer.dart';

class PatientHistoryVm extends ChangeNotifier {
  final RepositoryLayer repositoryLayer;

  PatientHistoryVm(this.repositoryLayer);

  bool loading = false;
  List<PatientData> history = [];

  Future<void> fetchPatientHistory() async {
  try {
    loading = true;
    notifyListeners();

    final patientResponse = await repositoryLayer.fetchPatientVisitHistory();
    history = patientResponse.results.data;

    debugPrint("Fetched ${history.length} patient visits");
  } catch (e, st) {
    debugPrint("Patient history error: $e");
    debugPrintStack(stackTrace: st);
    history = [];
  } finally {
    loading = false;
    notifyListeners();
  }
}

}
