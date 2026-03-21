import 'package:flutter/material.dart';

enum SupportType { cash, kind }

extension SupportTypeX on SupportType {
  String get label =>
      this == SupportType.cash ? 'Cash Support' : 'Kind Support';

  String get shortLabel => this == SupportType.cash ? 'Cash' : 'Kind';

  IconData get icon =>
      this == SupportType.cash ? Icons.payments_outlined : Icons.inventory_2_outlined;
}

class SupportTransaction {
  SupportTransaction({
    required this.id,
    required this.type,
    required this.farmerId,
    required this.farmerName,
    required this.date,
    required this.statusLabel,
    this.amount,
    this.itemName,
    required this.purpose,
    required this.acknowledged,
  });

  final String id;
  final SupportType type;
  final String farmerId;
  final String farmerName;
  final DateTime date;
  final String statusLabel;
  final double? amount;
  final String? itemName;
  final String purpose;
  final bool acknowledged;
}

class SupportDraft {
  SupportDraft({
    required this.type,
    required this.stepIndex,
    this.farmerId,
    this.cashAmount = 60000,
    this.itemName = 'Fertilizer',
    this.purpose = 'Input Support',
    DateTime? date,
  }) : date = date ?? DateTime(2026, 1, 25);

  final SupportType type;
  final int stepIndex;
  final String? farmerId;
  final double cashAmount;
  final String itemName;
  final String purpose;
  final DateTime date;

  SupportDraft copyWith({
    SupportType? type,
    int? stepIndex,
    String? farmerId,
    double? cashAmount,
    String? itemName,
    String? purpose,
    DateTime? date,
  }) {
    return SupportDraft(
      type: type ?? this.type,
      stepIndex: stepIndex ?? this.stepIndex,
      farmerId: farmerId ?? this.farmerId,
      cashAmount: cashAmount ?? this.cashAmount,
      itemName: itemName ?? this.itemName,
      purpose: purpose ?? this.purpose,
      date: date ?? this.date,
    );
  }
}
