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
        return 'Harvesting';
      case ProcurementStep.packaging:
        return 'Packaging';
      case ProcurementStep.weighing:
        return 'Weighing';
      case ProcurementStep.price:
        return 'Price';
      case ProcurementStep.receipt:
        return 'Receipt';
      case ProcurementStep.transport:
        return 'Transport';
    }
  }
}

class ProcurementReceipt {
  ProcurementReceipt({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.date,
    required this.harvestDateTime,
    required this.harvestedQtyKg,
    required this.finalQtyKg,
    required this.ratePerKg,
    required this.receiptNo,
    required this.carrierNumber,
    required this.driverName,
    required this.transportNotes,
    this.message,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final DateTime date;
  final DateTime harvestDateTime;
  final double harvestedQtyKg;
  final double finalQtyKg;
  final double ratePerKg;
  final String receiptNo;
  final String carrierNumber;
  final String driverName;
  final String transportNotes;
  final String? message;

  double get totalAmount => finalQtyKg * ratePerKg;
}

class ProcurementDraft {
  ProcurementDraft({
    required this.farmerId,
    this.stepIndex = 0,
    DateTime? harvestingDate,
    this.harvestingTime = const TimeOfDay(hour: 15, minute: 0),
    this.quantityHarvestedKg = 380,
    this.packagingStatus = 'Completed',
    DateTime? packagingDate,
    this.packagingNotes = 'Packed in 25kg crates.',
    DateTime? weighingDate,
    this.finalWeighingQtyKg = 420,
    this.weighingNotes = 'Packed and weighed at the field collection point.',
    this.ratePerKg = 450,
    this.receiptMessage = 'Share the receipt with the farmer after confirmation.',
    DateTime? transportDate,
    this.carrierNumber = 'TRK-5582',
    this.driverName = 'Name Surname',
    this.driverPhone = '02156-64456',
    this.transportNotes = 'Pickup from Trishal collection point.',
  })
      : harvestingDate = harvestingDate ?? DateTime(2026, 1, 25),
        packagingDate = packagingDate ?? DateTime(2026, 1, 25),
        weighingDate = weighingDate ?? DateTime(2026, 1, 25),
        transportDate = transportDate ?? DateTime(2026, 1, 25);

  final String farmerId;
  final int stepIndex;
  final DateTime harvestingDate;
  final TimeOfDay harvestingTime;
  final double quantityHarvestedKg;
  final String packagingStatus;
  final DateTime packagingDate;
  final String packagingNotes;
  final DateTime weighingDate;
  final double finalWeighingQtyKg;
  final String weighingNotes;
  final double ratePerKg;
  final String receiptMessage;
  final DateTime transportDate;
  final String carrierNumber;
  final String driverName;
  final String driverPhone;
  final String transportNotes;

  ProcurementDraft copyWith({
    String? farmerId,
    int? stepIndex,
    DateTime? harvestingDate,
    TimeOfDay? harvestingTime,
    double? quantityHarvestedKg,
    String? packagingStatus,
    DateTime? packagingDate,
    String? packagingNotes,
    DateTime? weighingDate,
    double? finalWeighingQtyKg,
    String? weighingNotes,
    double? ratePerKg,
    String? receiptMessage,
    DateTime? transportDate,
    String? carrierNumber,
    String? driverName,
    String? driverPhone,
    String? transportNotes,
  }) {
    return ProcurementDraft(
      farmerId: farmerId ?? this.farmerId,
      stepIndex: stepIndex ?? this.stepIndex,
      harvestingDate: harvestingDate ?? this.harvestingDate,
      harvestingTime: harvestingTime ?? this.harvestingTime,
      quantityHarvestedKg: quantityHarvestedKg ?? this.quantityHarvestedKg,
      packagingStatus: packagingStatus ?? this.packagingStatus,
      packagingDate: packagingDate ?? this.packagingDate,
      packagingNotes: packagingNotes ?? this.packagingNotes,
      weighingDate: weighingDate ?? this.weighingDate,
      finalWeighingQtyKg: finalWeighingQtyKg ?? this.finalWeighingQtyKg,
      weighingNotes: weighingNotes ?? this.weighingNotes,
      ratePerKg: ratePerKg ?? this.ratePerKg,
      receiptMessage: receiptMessage ?? this.receiptMessage,
      transportDate: transportDate ?? this.transportDate,
      carrierNumber: carrierNumber ?? this.carrierNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      transportNotes: transportNotes ?? this.transportNotes,
    );
  }
}
