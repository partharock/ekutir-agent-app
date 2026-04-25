import '../utils/translation_service.dart';
enum CropActivityType {
  nurseryStart,
  transplanting,
  growthMonitoring,
  inputApplication,
  harvestWindowStart,
  harvestWindowEnd,
}

enum CropActivityStatus { planned, inProgress, completed }

extension CropActivityStatusX on CropActivityStatus {
  String get label {
    switch (this) {
      case CropActivityStatus.planned:
        return 'Planned'.tr;
      case CropActivityStatus.inProgress:
        return 'In Progress'.tr;
      case CropActivityStatus.completed:
        return 'Completed'.tr;
    }
  }
}

class CropPlanActivity {
  const CropPlanActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.plannedDate,
    required this.detail,
    required this.status,
  });

  final String id;
  final CropActivityType type;
  final String title;
  final DateTime plannedDate;
  final String detail;
  final CropActivityStatus status;
  
  bool get completed => status == CropActivityStatus.completed;

  bool get isHarvestWindow =>
      type == CropActivityType.harvestWindowStart ||
      type == CropActivityType.harvestWindowEnd;

  CropPlanActivity copyWith({
    String? id,
    CropActivityType? type,
    String? title,
    DateTime? plannedDate,
    String? detail,
    CropActivityStatus? status,
  }) {
    return CropPlanActivity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      plannedDate: plannedDate ?? this.plannedDate,
      detail: detail ?? this.detail,
      status: status ?? this.status,
    );
  }
}

enum AlertSeverity { low, medium, high }

extension AlertSeverityX on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.low: return 'Low'.tr;
      case AlertSeverity.medium: return 'Medium'.tr;
      case AlertSeverity.high: return 'High'.tr;
    }
  }
}

class FieldIssueAlert {
  const FieldIssueAlert({
    required this.id,
    required this.farmerId,
    required this.description,
    required this.severity,
    this.photoPath,
    required this.reportedAt,
    this.resolved = false,
  });

  final String id;
  final String farmerId;
  final String description;
  final AlertSeverity severity;
  final String? photoPath; // optional local UI path, e.g. from image_picker
  final DateTime reportedAt;
  final bool resolved;

  FieldIssueAlert copyWith({
    String? id,
    String? farmerId,
    String? description,
    AlertSeverity? severity,
    String? photoPath,
    DateTime? reportedAt,
    bool? resolved,
  }) {
    return FieldIssueAlert(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      photoPath: photoPath ?? this.photoPath,
      reportedAt: reportedAt ?? this.reportedAt,
      resolved: resolved ?? this.resolved,
    );
  }
}
