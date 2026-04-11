import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FarmerStatus { willing, booked }

enum FarmerStage {
  willing,
  booked,
  nursery,
  growth,
  harvest,
  procurement,
  settlementCompleted,
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
      case FarmerStage.growth:
        return 'Growth';
      case FarmerStage.harvest:
        return 'Harvest';
      case FarmerStage.procurement:
        return 'Procurement';
      case FarmerStage.settlementCompleted:
        return 'Settlement Completed';
    }
  }
}

Color stageBackgroundColor(FarmerStage stage) {
  switch (stage) {
    case FarmerStage.willing:
      return AppColors.brandGreenLight;
    case FarmerStage.booked:
      return AppColors.brandBlueLight;
    case FarmerStage.nursery:
      return AppColors.heroMist;
    case FarmerStage.growth:
      return const Color(0xFFEFF7E3);
    case FarmerStage.harvest:
      return const Color(0xFFFFF1D9);
    case FarmerStage.procurement:
      return const Color(0xFFEAE7FF);
    case FarmerStage.settlementCompleted:
      return const Color(0xFFE5F5EC);
  }
}

Color stageForegroundColor(FarmerStage stage) {
  switch (stage) {
    case FarmerStage.willing:
      return AppColors.brandGreenDark;
    case FarmerStage.booked:
      return AppColors.brandBlue;
    case FarmerStage.nursery:
    case FarmerStage.growth:
      return AppColors.heroForest;
    case FarmerStage.harvest:
      return const Color(0xFF9C5C00);
    case FarmerStage.procurement:
      return const Color(0xFF5443B6);
    case FarmerStage.settlementCompleted:
      return const Color(0xFF157347);
  }
}

String stageHelperText(FarmerStage stage) {
  switch (stage) {
    case FarmerStage.willing:
      return 'Proceed to cash support to activate the partnership.';
    case FarmerStage.booked:
      return 'Cash support has been acknowledged. Nursery preparation is next.';
    case FarmerStage.nursery:
      return 'Nursery activities are underway for this farmer.';
    case FarmerStage.growth:
      return 'Growth monitoring and planned visits are active.';
    case FarmerStage.harvest:
      return 'Harvest window is active. Procurement can be scheduled.';
    case FarmerStage.procurement:
      return 'Harvesting and procurement records are in progress or complete.';
    case FarmerStage.settlementCompleted:
      return 'Reconciliation is complete for this crop cycle.';
  }
}

class PlotLocation {
  const PlotLocation({
    required this.latitude,
    required this.longitude,
    this.displayAddress,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final String? displayAddress;
  final DateTime capturedAt;

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  PlotLocation copyWith({
    double? latitude,
    double? longitude,
    String? displayAddress,
    DateTime? capturedAt,
  }) {
    return PlotLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      displayAddress: displayAddress ?? this.displayAddress,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}

class FarmerProfile {
  const FarmerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    this.plotLocation,
    required this.totalLandAcres,
    required this.crop,
    required this.season,
    required this.status,
    required this.stage,
    required this.nurseryLandAcres,
    required this.mainLandAcres,
    required this.landDetails,
    required this.supportPreview,
  });

  final String id;
  final String name;
  final String phone;
  final String location;
  final PlotLocation? plotLocation;
  final double totalLandAcres;
  final String crop;
  final String season;
  final FarmerStatus status;
  final FarmerStage stage;
  final double nurseryLandAcres;
  final double mainLandAcres;
  final String landDetails;
  final Map<String, String> supportPreview;

  FarmerProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? location,
    PlotLocation? plotLocation,
    double? totalLandAcres,
    String? crop,
    String? season,
    FarmerStatus? status,
    FarmerStage? stage,
    double? nurseryLandAcres,
    double? mainLandAcres,
    String? landDetails,
    Map<String, String>? supportPreview,
  }) {
    return FarmerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      plotLocation: plotLocation ?? this.plotLocation,
      totalLandAcres: totalLandAcres ?? this.totalLandAcres,
      crop: crop ?? this.crop,
      season: season ?? this.season,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      nurseryLandAcres: nurseryLandAcres ?? this.nurseryLandAcres,
      mainLandAcres: mainLandAcres ?? this.mainLandAcres,
      landDetails: landDetails ?? this.landDetails,
      supportPreview: supportPreview ?? this.supportPreview,
    );
  }
}

class NewFarmerDraft {
  const NewFarmerDraft({
    required this.name,
    required this.phone,
    required this.location,
    this.plotLocation,
    required this.crop,
    required this.season,
    required this.landDetails,
    required this.totalLandAcres,
    required this.nurseryLandAcres,
    required this.mainLandAcres,
  });

  final String name;
  final String phone;
  final String location;
  final PlotLocation? plotLocation;
  final String crop;
  final String season;
  final String landDetails;
  final double totalLandAcres;
  final double nurseryLandAcres;
  final double mainLandAcres;

  NewFarmerDraft copyWith({
    String? name,
    String? phone,
    String? location,
    PlotLocation? plotLocation,
    String? crop,
    String? season,
    String? landDetails,
    double? totalLandAcres,
    double? nurseryLandAcres,
    double? mainLandAcres,
  }) {
    return NewFarmerDraft(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      plotLocation: plotLocation ?? this.plotLocation,
      crop: crop ?? this.crop,
      season: season ?? this.season,
      landDetails: landDetails ?? this.landDetails,
      totalLandAcres: totalLandAcres ?? this.totalLandAcres,
      nurseryLandAcres: nurseryLandAcres ?? this.nurseryLandAcres,
      mainLandAcres: mainLandAcres ?? this.mainLandAcres,
    );
  }
}
