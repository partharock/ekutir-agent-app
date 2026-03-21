class CropPlanActivity {
  CropPlanActivity({
    required this.id,
    required this.title,
    required this.plannedDate,
    required this.detail,
    required this.status,
    required this.completed,
  });

  final String id;
  final String title;
  final DateTime plannedDate;
  final String detail;
  final String status;
  final bool completed;
}
