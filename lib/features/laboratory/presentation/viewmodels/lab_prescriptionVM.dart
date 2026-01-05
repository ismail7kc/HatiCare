import 'package:flutter/material.dart';
import 'package:haticare/features/laboratory/presentation/lab_repository_layer.dart';

class LabPrescriptionvm extends ChangeNotifier {
  final LabRepositoryLayer _labRepositoryLayer;

  LabPrescriptionvm(this._labRepositoryLayer);

  Future<void> laboratoryPrescriptionList() async {
    notifyListeners();

    try {
      final response = await _labRepositoryLayer.laboratoryPrescriptionList();
      if (response['success'] == true && response['data'] != null) {
        debugPrint('Laboratory Test Api triggered without any Errror');
      }
    } catch (error) {
      debugPrint('Laboratory Test Error: $error');
    } finally {
      notifyListeners();
    }
  }
}
