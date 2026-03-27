import 'package:flutter/material.dart';

enum SupportType { cash, kind }

enum CashSupportStage { booked, received, paid, acknowledged }

enum KindSupportStage { given, acknowledged }

extension SupportTypeX on SupportType {
  String get label =>
      this == SupportType.cash ? 'Cash Support' : 'Kind Support';

  String get shortLabel => this == SupportType.cash ? 'Cash' : 'Kind';

  IconData get icon => this == SupportType.cash
      ? Icons.payments_outlined
      : Icons.inventory_2_outlined;
}

extension CashSupportStageX on CashSupportStage {
  String get label {
    switch (this) {
      case CashSupportStage.booked:
        return 'Booked';
      case CashSupportStage.received:
        return 'Received';
      case CashSupportStage.paid:
        return 'Paid';
      case CashSupportStage.acknowledged:
        return 'Acknowledged';
    }
  }
}

extension KindSupportStageX on KindSupportStage {
  String get label {
    switch (this) {
      case KindSupportStage.given:
        return 'Given';
      case KindSupportStage.acknowledged:
        return 'Acknowledged';
    }
  }
}

class SupportRecord {
  const SupportRecord({
    required this.id,
    required this.type,
    required this.farmerId,
    required this.farmerName,
    required this.landDetails,
    required this.cropContext,
    required this.disbursementDate,
    required this.createdAt,
    required this.updatedAt,
    this.cashAmount,
    this.itemName,
    this.quantity,
    this.unit,
    this.kindValue,
    this.cashStage,
    this.kindStage,
    this.confirmationCode,
    this.enteredOtp,
    this.otpVerified = false,
    this.finalized = false,
  });

  final String id;
  final SupportType type;
  final String farmerId;
  final String farmerName;
  final String landDetails;
  final String cropContext;
  final DateTime disbursementDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? cashAmount;
  final String? itemName;
  final double? quantity;
  final String? unit;
  final double? kindValue;
  final CashSupportStage? cashStage;
  final KindSupportStage? kindStage;
  final String? confirmationCode;
  final String? enteredOtp;
  final bool otpVerified;
  final bool finalized;

  bool get isAcknowledged => type == SupportType.cash
      ? cashStage == CashSupportStage.acknowledged
      : kindStage == KindSupportStage.acknowledged;

  bool get isOtpPending => confirmationCode != null && !otpVerified;

  String get statusLabel => type == SupportType.cash
      ? (cashStage?.label ?? CashSupportStage.booked.label)
      : (kindStage?.label ?? KindSupportStage.given.label);

  SupportRecord copyWith({
    String? id,
    SupportType? type,
    String? farmerId,
    String? farmerName,
    String? landDetails,
    String? cropContext,
    DateTime? disbursementDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? cashAmount,
    String? itemName,
    double? quantity,
    String? unit,
    double? kindValue,
    CashSupportStage? cashStage,
    KindSupportStage? kindStage,
    String? confirmationCode,
    String? enteredOtp,
    bool? otpVerified,
    bool? finalized,
  }) {
    return SupportRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      landDetails: landDetails ?? this.landDetails,
      cropContext: cropContext ?? this.cropContext,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cashAmount: cashAmount ?? this.cashAmount,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      kindValue: kindValue ?? this.kindValue,
      cashStage: cashStage ?? this.cashStage,
      kindStage: kindStage ?? this.kindStage,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      enteredOtp: enteredOtp ?? this.enteredOtp,
      otpVerified: otpVerified ?? this.otpVerified,
      finalized: finalized ?? this.finalized,
    );
  }
}

class SupportFlowDraft {
  SupportFlowDraft({
    required this.type,
    required this.stepIndex,
    this.recordId,
    this.farmerId,
    this.landDetails = '',
    this.cropContext = '',
    this.cashAmount = 60000,
    DateTime? disbursementDate,
    this.itemName = 'Seeds',
    this.quantity = 10,
    this.unit = 'kg',
    this.kindValue = 8000,
    this.otpInput = '',
  }) : disbursementDate = disbursementDate ?? DateTime.now();

  final SupportType type;
  final int stepIndex;
  final String? recordId;
  final String? farmerId;
  final String landDetails;
  final String cropContext;
  final double cashAmount;
  final DateTime disbursementDate;
  final String itemName;
  final double quantity;
  final String unit;
  final double kindValue;
  final String otpInput;

  SupportFlowDraft copyWith({
    SupportType? type,
    int? stepIndex,
    String? recordId,
    String? farmerId,
    String? landDetails,
    String? cropContext,
    double? cashAmount,
    DateTime? disbursementDate,
    String? itemName,
    double? quantity,
    String? unit,
    double? kindValue,
    String? otpInput,
  }) {
    return SupportFlowDraft(
      type: type ?? this.type,
      stepIndex: stepIndex ?? this.stepIndex,
      recordId: recordId ?? this.recordId,
      farmerId: farmerId ?? this.farmerId,
      landDetails: landDetails ?? this.landDetails,
      cropContext: cropContext ?? this.cropContext,
      cashAmount: cashAmount ?? this.cashAmount,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      kindValue: kindValue ?? this.kindValue,
      otpInput: otpInput ?? this.otpInput,
    );
  }
}
