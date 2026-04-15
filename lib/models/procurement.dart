import '../utils/translation_service.dart';
import 'package:flutter/material.dart';

enum ProcurementStep {
  harvesting,
  packaging,
  weighing,
  price,
  receipt,
  transport,
}

extension ProcurementStepX on ProcurementStep {
  String get label {
    switch (this) {
      case ProcurementStep.harvesting:
        return 'Harvesting'.tr;
      case ProcurementStep.packaging:
        return 'Packaging'.tr;
      case ProcurementStep.weighing:
        return 'Weighing'.tr;
      case ProcurementStep.price:
        return 'Price'.tr;
      case ProcurementStep.receipt:
        return 'Receipt'.tr;
      case ProcurementStep.transport:
        return 'Transport'.tr;
    }
  }
}

class ProcurementRecord {
  const ProcurementRecord({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.crop,
    required this.createdAt,
    required this.updatedAt,
    required this.harvestDateOptions,
    this.selectedHarvestDate,
    this.harvestingTime = const TimeOfDay(hour: 8, minute: 0),
    this.quantityHarvestedKg,
    this.packagingDone = false,
    this.packagingDate,
    this.packagingNotes = '',
    this.weighingDone = false,
    this.weighingDate,
    this.finalWeighingQtyKg,
    this.weighingNotes = '',
    this.ratePerKg = 42,
    this.receiptGenerated = false,
    this.receiptNumber,
    this.receiptMessage = '',
    this.transportAssigned = false,
    this.transportDate,
    this.carrierNumber = '',
    this.transporterName = '',
    this.carrierCapacity = 0.0,
    this.transportNotes = '',
    this.submitted = false,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String crop;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DateTime> harvestDateOptions;
  final DateTime? selectedHarvestDate;
  final TimeOfDay harvestingTime;
  final double? quantityHarvestedKg;
  final bool packagingDone;
  final DateTime? packagingDate;
  final String packagingNotes;
  final bool weighingDone;
  final DateTime? weighingDate;
  final double? finalWeighingQtyKg;
  final String weighingNotes;
  final double ratePerKg;
  final bool receiptGenerated;
  final String? receiptNumber;
  final String receiptMessage;
  final bool transportAssigned;
  final DateTime? transportDate;
  final String carrierNumber;
  final String transporterName;
  final double carrierCapacity;
  final String transportNotes;
  final bool submitted;

  bool get hasHarvesting =>
      selectedHarvestDate != null && quantityHarvestedKg != null;

  bool get hasPrice => finalWeighingQtyKg != null && finalWeighingQtyKg! > 0;

  bool get isComplete =>
      hasHarvesting &&
      packagingDone &&
      weighingDone &&
      hasPrice &&
      receiptGenerated &&
      transportAssigned;

  double get totalAmount => (finalWeighingQtyKg ?? 0) * ratePerKg;

  List<ProcurementStep> get incompleteSteps {
    final steps = <ProcurementStep>[];
    if (!hasHarvesting) {
      steps.add(ProcurementStep.harvesting);
    }
    if (!packagingDone) {
      steps.add(ProcurementStep.packaging);
    }
    if (!weighingDone) {
      steps.add(ProcurementStep.weighing);
    }
    if (!hasPrice) {
      steps.add(ProcurementStep.price);
    }
    if (!receiptGenerated) {
      steps.add(ProcurementStep.receipt);
    }
    if (!transportAssigned) {
      steps.add(ProcurementStep.transport);
    }
    return steps;
  }

  ProcurementRecord copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? crop,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DateTime>? harvestDateOptions,
    DateTime? selectedHarvestDate,
    TimeOfDay? harvestingTime,
    double? quantityHarvestedKg,
    bool? packagingDone,
    DateTime? packagingDate,
    String? packagingNotes,
    bool? weighingDone,
    DateTime? weighingDate,
    double? finalWeighingQtyKg,
    String? weighingNotes,
    double? ratePerKg,
    bool? receiptGenerated,
    String? receiptNumber,
    String? receiptMessage,
    bool? transportAssigned,
    DateTime? transportDate,
    String? carrierNumber,
    String? transporterName,
    double? carrierCapacity,
    String? transportNotes,
    bool? submitted,
  }) {
    return ProcurementRecord(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      crop: crop ?? this.crop,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      harvestDateOptions: harvestDateOptions ?? this.harvestDateOptions,
      selectedHarvestDate: selectedHarvestDate ?? this.selectedHarvestDate,
      harvestingTime: harvestingTime ?? this.harvestingTime,
      quantityHarvestedKg: quantityHarvestedKg ?? this.quantityHarvestedKg,
      packagingDone: packagingDone ?? this.packagingDone,
      packagingDate: packagingDate ?? this.packagingDate,
      packagingNotes: packagingNotes ?? this.packagingNotes,
      weighingDone: weighingDone ?? this.weighingDone,
      weighingDate: weighingDate ?? this.weighingDate,
      finalWeighingQtyKg: finalWeighingQtyKg ?? this.finalWeighingQtyKg,
      weighingNotes: weighingNotes ?? this.weighingNotes,
      ratePerKg: ratePerKg ?? this.ratePerKg,
      receiptGenerated: receiptGenerated ?? this.receiptGenerated,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptMessage: receiptMessage ?? this.receiptMessage,
      transportAssigned: transportAssigned ?? this.transportAssigned,
      transportDate: transportDate ?? this.transportDate,
      carrierNumber: carrierNumber ?? this.carrierNumber,
      transporterName: transporterName ?? this.transporterName,
      carrierCapacity: carrierCapacity ?? this.carrierCapacity,
      transportNotes: transportNotes ?? this.transportNotes,
      submitted: submitted ?? this.submitted,
    );
  }
}
