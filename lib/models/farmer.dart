import '../utils/translation_service.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FarmerType { individual, group }

extension FarmerTypeX on FarmerType {
  String get label {
    switch (this) {
      case FarmerType.individual:
        return 'Individual';
      case FarmerType.group:
        return 'Group';
    }
  }
}

class BankDetails {
  const BankDetails({
    this.accountHolderName = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.upiId = '',
  });

  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;

  bool get isEmpty =>
      accountHolderName.isEmpty &&
      bankName.isEmpty &&
      accountNumber.isEmpty &&
      ifscCode.isEmpty;

  BankDetails copyWith({
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) {
    return BankDetails(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
    );
  }
}

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
        return 'Willing'.tr;
      case FarmerStatus.booked:
        return 'Booked'.tr;
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
        return 'Willing'.tr;
      case FarmerStage.booked:
        return 'Booked'.tr;
      case FarmerStage.nursery:
        return 'Nursery'.tr;
      case FarmerStage.growth:
        return 'Growth'.tr;
      case FarmerStage.harvest:
        return 'Harvest'.tr;
      case FarmerStage.procurement:
        return 'Procurement'.tr;
      case FarmerStage.settlementCompleted:
        return 'Settlement Completed'.tr;
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
      return 'Proceed to cash support to activate the partnership.'.tr;
    case FarmerStage.booked:
      return 'Cash support has been acknowledged. Nursery preparation is next.'.tr;
    case FarmerStage.nursery:
      return 'Nursery activities are underway for this farmer.'.tr;
    case FarmerStage.growth:
      return 'Growth monitoring and planned visits are active.'.tr;
    case FarmerStage.harvest:
      return 'Harvest window is active. Procurement can be scheduled.'.tr;
    case FarmerStage.procurement:
      return 'Harvesting and procurement records are in progress or complete.'.tr;
    case FarmerStage.settlementCompleted:
      return 'Reconciliation is complete for this crop cycle.'.tr;
  }
}

class PlotCoordinate {
  const PlotCoordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class PlotLocation {
  const PlotLocation({
    required this.polygonPoints,
    this.displayAddress,
    required this.capturedAt,
  });

  final List<PlotCoordinate> polygonPoints;
  final String? displayAddress;
  final DateTime capturedAt;

  PlotCoordinate get center {
    if (polygonPoints.isEmpty) return const PlotCoordinate(0, 0);
    double sumLat = 0;
    double sumLng = 0;
    for (final p in polygonPoints) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return PlotCoordinate(
      sumLat / polygonPoints.length,
      sumLng / polygonPoints.length,
    );
  }

  String get coordinatesLabel {
    if (polygonPoints.isEmpty) return 'No bounds';
    final c = center;
    return '${c.latitude.toStringAsFixed(6)}, ${c.longitude.toStringAsFixed(6)} (Polygon)';
  }

  PlotLocation copyWith({
    List<PlotCoordinate>? polygonPoints,
    String? displayAddress,
    DateTime? capturedAt,
  }) {
    return PlotLocation(
      polygonPoints: polygonPoints ?? this.polygonPoints,
      displayAddress: displayAddress ?? this.displayAddress,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}

class LandRecord {
  const LandRecord({
    required this.id,
    required this.crop,
    required this.season,
    required this.totalAcres,
    required this.nurseryAcres,
    required this.mainAcres,
    required this.details,
    this.plotLocation,
  });

  final String id;
  final String crop;
  final String season;
  final double totalAcres;
  final double nurseryAcres;
  final double mainAcres;
  final String details;
  final PlotLocation? plotLocation;

  LandRecord copyWith({
    String? id,
    String? crop,
    String? season,
    double? totalAcres,
    double? nurseryAcres,
    double? mainAcres,
    String? details,
    PlotLocation? plotLocation,
  }) {
    return LandRecord(
      id: id ?? this.id,
      crop: crop ?? this.crop,
      season: season ?? this.season,
      totalAcres: totalAcres ?? this.totalAcres,
      nurseryAcres: nurseryAcres ?? this.nurseryAcres,
      mainAcres: mainAcres ?? this.mainAcres,
      details: details ?? this.details,
      plotLocation: plotLocation ?? this.plotLocation,
    );
  }
}

class FarmerProfile {
  const FarmerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.lands,
    required this.status,
    required this.stage,
    required this.supportPreview,
    this.farmerType = FarmerType.individual,
    this.groupName,
    this.groupMembers,
    this.aadharNumber,
    this.bankDetails,
    this.uniqueId,
  });

  final String id;
  final String name;
  final String phone;
  final String location;
  final List<LandRecord> lands;
  final FarmerStatus status;
  final FarmerStage stage;
  
  double get totalLandAcres => lands.fold(0.0, (s, l) => s + l.totalAcres);
  double get nurseryLandAcres => lands.fold(0.0, (s, l) => s + l.nurseryAcres);
  double get mainLandAcres => lands.fold(0.0, (s, l) => s + l.mainAcres);
  String get crop => lands.isEmpty ? '' : lands.first.crop;
  String get season => lands.isEmpty ? '' : lands.first.season;
  PlotLocation? get plotLocation => lands.isEmpty ? null : lands.first.plotLocation;
  String get landDetails => lands.isEmpty ? '' : lands.first.details;
  final Map<String, String> supportPreview;
  final FarmerType farmerType;
  final String? groupName;
  final int? groupMembers;
  final String? aadharNumber;
  final BankDetails? bankDetails;
  final String? uniqueId;

  FarmerProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? location,
    List<LandRecord>? lands,
    FarmerStatus? status,
    FarmerStage? stage,
    Map<String, String>? supportPreview,
    FarmerType? farmerType,
    String? groupName,
    int? groupMembers,
    String? aadharNumber,
    BankDetails? bankDetails,
    String? uniqueId,
  }) {
    return FarmerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      lands: lands ?? this.lands,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      supportPreview: supportPreview ?? this.supportPreview,
      farmerType: farmerType ?? this.farmerType,
      groupName: groupName ?? this.groupName,
      groupMembers: groupMembers ?? this.groupMembers,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      bankDetails: bankDetails ?? this.bankDetails,
      uniqueId: uniqueId ?? this.uniqueId,
    );
  }
}

class NewFarmerDraft {
  const NewFarmerDraft({
    required this.name,
    required this.phone,
    required this.location,
    required this.lands,
    this.farmerType = FarmerType.individual,
    this.groupName,
    this.groupMembers,
    this.aadharNumber,
    this.bankDetails,
  });

  final String name;
  final String phone;
  final String location;
  final List<LandRecord> lands;

  double get totalLandAcres => lands.fold(0.0, (s, l) => s + l.totalAcres);
  double get nurseryLandAcres => lands.fold(0.0, (s, l) => s + l.nurseryAcres);
  double get mainLandAcres => lands.fold(0.0, (s, l) => s + l.mainAcres);
  String get crop => lands.isEmpty ? '' : lands.first.crop;
  String get season => lands.isEmpty ? '' : lands.first.season;
  PlotLocation? get plotLocation => lands.isEmpty ? null : lands.first.plotLocation;
  String get landDetails => lands.isEmpty ? '' : lands.first.details;
  final FarmerType farmerType;
  final String? groupName;
  final int? groupMembers;
  final String? aadharNumber;
  final BankDetails? bankDetails;

  NewFarmerDraft copyWith({
    String? name,
    String? phone,
    String? location,
    List<LandRecord>? lands,
    FarmerType? farmerType,
    String? groupName,
    int? groupMembers,
    String? aadharNumber,
    BankDetails? bankDetails,
  }) {
    return NewFarmerDraft(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      lands: lands ?? this.lands,
      farmerType: farmerType ?? this.farmerType,
      groupName: groupName ?? this.groupName,
      groupMembers: groupMembers ?? this.groupMembers,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}
