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
