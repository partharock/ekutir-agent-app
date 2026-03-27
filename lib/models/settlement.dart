enum SettlementStatus { pendingReconciliation, completed }

extension SettlementStatusX on SettlementStatus {
  String get label {
    switch (this) {
      case SettlementStatus.pendingReconciliation:
        return 'Pending Reconciliation';
      case SettlementStatus.completed:
        return 'Completed';
    }
  }
}

class SettlementRecord {
  const SettlementRecord({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.supportValue,
    required this.procurementValue,
    required this.netSettlement,
    required this.status,
    this.completedAt,
    this.notes = '',
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final double supportValue;
  final double procurementValue;
  final double netSettlement;
  final SettlementStatus status;
  final DateTime? completedAt;
  final String notes;

  SettlementRecord copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    double? supportValue,
    double? procurementValue,
    double? netSettlement,
    SettlementStatus? status,
    DateTime? completedAt,
    String? notes,
  }) {
    return SettlementRecord(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      supportValue: supportValue ?? this.supportValue,
      procurementValue: procurementValue ?? this.procurementValue,
      netSettlement: netSettlement ?? this.netSettlement,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}
