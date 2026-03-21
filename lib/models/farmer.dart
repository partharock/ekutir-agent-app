import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'support.dart';
import 'procurement.dart';
import 'crop_plan.dart';

enum FarmerStatus { willing, booked }

enum FarmerStage {
  willing,
  booked,
  nursery,
  transplanted,
  growth,
  harvest,
  procurement,
  completed,
}

extension FarmerStatusX on FarmerStatus {
  String get label {
    switch (this) {
      case FarmerStatus.willing:
        return 'Willing';
      case FarmerStatus.booked:
        return 'Booked';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case FarmerStatus.willing:
        return AppColors.brandGreenLight;
      case FarmerStatus.booked:
        return AppColors.brandBlueLight;
    }
  }

  Color get foregroundColor {
    switch (this) {
      case FarmerStatus.willing:
        return AppColors.brandGreenDark;
      case FarmerStatus.booked:
        return AppColors.brandBlue;
    }
  }
}

extension FarmerStageX on FarmerStage {
  String get label {
    switch (this) {
      case FarmerStage.willing:
        return 'Willing';
      case FarmerStage.booked:
        return 'Booked';
      case FarmerStage.nursery:
        return 'Nursery';
      case FarmerStage.transplanted:
        return 'Transplanted';
      case FarmerStage.growth:
        return 'Growth';
      case FarmerStage.harvest:
        return 'Harvest';
      case FarmerStage.procurement:
        return 'Procurement';
      case FarmerStage.completed:
        return 'Completed';
    }
  }
}

Color stageBackgroundColor(FarmerStage stage) {
  switch (stage) {
    case FarmerStage.booked:
      return AppColors.brandBlueLight;
    case FarmerStage.willing:
      return AppColors.brandGreenLight;
    case FarmerStage.nursery:
    case FarmerStage.transplanted:
    case FarmerStage.growth:
    case FarmerStage.harvest:
    case FarmerStage.procurement:
    case FarmerStage.completed:
      return AppColors.pageBackground;
  }
}

Color stageForegroundColor(FarmerStage stage) {
  switch (stage) {
    case FarmerStage.booked:
      return AppColors.brandBlue;
    case FarmerStage.willing:
      return AppColors.brandGreenDark;
    case FarmerStage.nursery:
    case FarmerStage.transplanted:
    case FarmerStage.growth:
    case FarmerStage.harvest:
    case FarmerStage.procurement:
    case FarmerStage.completed:
      return AppColors.textSecondary;
  }
}

String stageHelperText(FarmerStage stage) {
  switch (stage) {
    case FarmerStage.willing:
      return 'Booked status is activated after cash advance disbursal and OTP acknowledgment.';
    case FarmerStage.booked:
      return 'Booked status is activated after cash advance disbursal and OTP acknowledgment.';
    case FarmerStage.nursery:
      return 'Nursery preparation has started for this farmer.';
    case FarmerStage.transplanted:
    case FarmerStage.growth:
      return 'Transplanting completed and growth monitoring is underway.';
    case FarmerStage.harvest:
      return 'Harvest window is active for the current crop cycle.';
    case FarmerStage.procurement:
      return 'Procurement flow is active and receipt processing is in progress.';
    case FarmerStage.completed:
      return 'The current season cycle is completed.';
  }
}

class FarmerProfile {
  FarmerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.totalLandAcres,
    required this.crop,
    required this.season,
    required this.status,
    required this.stage,
    required this.nurseryLandAcres,
    required this.mainLandAcres,
    required this.cashEligibility,
    required this.kindSupportItems,
    required this.supportHistory,
    required this.procurementHistory,
    required this.activities,
  });

  final String id;
  final String name;
  final String phone;
  final String location;
  final double totalLandAcres;
  final String crop;
  final String season;
  FarmerStatus status;
  FarmerStage stage;
  final double nurseryLandAcres;
  final double mainLandAcres;
  final double cashEligibility;
  final Map<String, String> kindSupportItems;
  final List<SupportTransaction> supportHistory;
  final List<ProcurementReceipt> procurementHistory;
  final List<CropPlanActivity> activities;
}
