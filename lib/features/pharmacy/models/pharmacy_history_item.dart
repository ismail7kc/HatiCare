
enum HistoryAction {
  selectedFull,
  respondedFull,
  respondedPartial,
  selectedPartial,
}

class PharmacyHistoryItem {
  final int prescriptionId;
  final HistoryAction action;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  PharmacyHistoryItem({
    required this.prescriptionId,
    required this.action,
    required this.createdAt,
    required this.metadata,
  });

  factory PharmacyHistoryItem.fromJson(Map<String, dynamic> json) {
    try {
      // Parse action
      HistoryAction action = HistoryAction.selectedFull;
      if (json['action'] != null) {
        final actionStr = json['action'].toString().toLowerCase();
        switch (actionStr) {
          case 'selected_full':
            action = HistoryAction.selectedFull;
            break;
          case 'responded_full':
            action = HistoryAction.respondedFull;
            break;
          case 'responded_partial':
            action = HistoryAction.respondedPartial;
            break;
          case 'selected_partial':
            action = HistoryAction.selectedPartial;
            break;
        }
      }

      // Parse date
      DateTime createdAt = DateTime.now();
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at'].toString());
      }

      return PharmacyHistoryItem(
        prescriptionId: int.tryParse(json['prescription_id']?.toString() ?? '0') ?? 0,
        action: action,
        createdAt: createdAt,
        metadata: json['metadata'] is Map<String, dynamic> 
            ? json['metadata'] as Map<String, dynamic>
            : {},
      );
    } catch (e) {
      // Return a default object if parsing fails
      return PharmacyHistoryItem(
        prescriptionId: int.tryParse(json['prescription_id']?.toString() ?? '0') ?? 0,
        action: HistoryAction.selectedFull,
        createdAt: DateTime.now(),
        metadata: {},
      );
    }
  }

  String get actionText {
    switch (action) {
      case HistoryAction.selectedFull:
        return 'Selected';
      case HistoryAction.respondedFull:
        return 'Fully Responded';
      case HistoryAction.respondedPartial:
        return 'Partially Responded';
      case HistoryAction.selectedPartial:
        return 'Partially Selected';
    }
  }

  String get statusText {
    switch (action) {
      case HistoryAction.selectedFull:
        return 'Selected';
      case HistoryAction.respondedFull:
        return 'Fully Available';
      case HistoryAction.respondedPartial:
        return 'Partially Available';
      case HistoryAction.selectedPartial:
        return 'Partially Selected';
    }
  }

  List<HistoryMedicationItem> get medications {
    if (metadata['items'] is List) {
      final itemsList = metadata['items'] as List<dynamic>;
      return itemsList
          .map((item) => HistoryMedicationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  String? get comment => metadata['comment']?.toString();
  
  double? get score => double.tryParse(metadata['score']?.toString() ?? '');
}

class HistoryMedicationItem {
  final String name;
  final String notes;
  final String strength;
  final int requiredQty;
  final int availableQty;

  HistoryMedicationItem({
    required this.name,
    required this.notes,
    required this.strength,
    required this.requiredQty,
    required this.availableQty,
  });

  factory HistoryMedicationItem.fromJson(Map<String, dynamic> json) {
    return HistoryMedicationItem(
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      strength: json['strength']?.toString() ?? '',
      requiredQty: int.tryParse(json['required_qty']?.toString() ?? '0') ?? 0,
      availableQty: int.tryParse(json['available_qty']?.toString() ?? '0') ?? 0,
    );
  }

  String get availabilityStatus {
    if (availableQty >= requiredQty) {
      return 'Available';
    } else if (availableQty > 0) {
      return 'Partially Available';
    } else {
      return 'Not Available';
    }
  }
}
