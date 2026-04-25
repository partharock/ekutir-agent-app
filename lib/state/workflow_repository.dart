import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop_plan.dart';
import '../models/farmer.dart';
import '../models/procurement.dart';
import '../models/settlement.dart';
import '../models/support.dart';

abstract class WorkflowRepository {
  List<FarmerProfile> get farmers;
  List<CropPlanActivity> activitiesFor(String farmerId);
  List<SupportRecord> supportFor(String farmerId);
  List<ProcurementRecord> procurementFor(String farmerId);
  SettlementRecord? settlementFor(String farmerId);

  FarmerProfile farmerById(String farmerId);
  SupportRecord? supportById(String recordId);
  ProcurementRecord? procurementById(String recordId);

  void saveFarmer(FarmerProfile farmer);
  void saveActivities(String farmerId, List<CropPlanActivity> activities);
  void saveSupport(SupportRecord record);
  void saveProcurement(ProcurementRecord record);
  void saveSettlement(SettlementRecord record);
}

Map<String, String> defaultSupportPreview() => const {
      'Cash Advance': 'Up to ₹60,000',
      'Seeds': '20 kg',
      'Fertilizer': '2 bags',
      'Pesticides': '5 bottles',
    };

List<CropPlanActivity> buildCropPlanActivities({
  required String farmerId,
  required FarmerStage stage,
  required DateTime today,
}) {
  final seedToday = _dateOnly(today);

  CropActivityStatus statusFor(CropActivityType type) {
    switch (type) {
      case CropActivityType.nurseryStart:
        return stage.index >= FarmerStage.nursery.index
            ? CropActivityStatus.completed
            : CropActivityStatus.planned;
      case CropActivityType.transplanting:
        return stage.index >= FarmerStage.growth.index
            ? CropActivityStatus.completed
            : CropActivityStatus.inProgress;
      case CropActivityType.growthMonitoring:
        return stage.index >= FarmerStage.growth.index
            ? CropActivityStatus.inProgress
            : CropActivityStatus.planned;
      case CropActivityType.inputApplication:
        return stage.index >= FarmerStage.growth.index
            ? CropActivityStatus.inProgress
            : CropActivityStatus.planned;
      case CropActivityType.harvestWindowStart:
        return stage.index >= FarmerStage.harvest.index
            ? CropActivityStatus.inProgress
            : CropActivityStatus.planned;
      case CropActivityType.harvestWindowEnd:
        return stage.index >= FarmerStage.procurement.index
            ? CropActivityStatus.completed
            : CropActivityStatus.planned;
    }
  }

  return [
    CropPlanActivity(
      id: '${farmerId}_n1',
      type: CropActivityType.nurseryStart,
      title: 'Nursery Start'.tr,
      plannedDate: seedToday.subtract(const Duration(days: 18)),
      detail: 'Prepare nursery bed and arrange saplings.',
      status: statusFor(CropActivityType.nurseryStart),
    ),
    CropPlanActivity(
      id: '${farmerId}_t1',
      type: CropActivityType.transplanting,
      title: 'Transplanting'.tr,
      plannedDate: seedToday.subtract(const Duration(days: 8)),
      detail: 'Move nursery plants to the main field.',
      status: statusFor(CropActivityType.transplanting),
    ),
    CropPlanActivity(
      id: '${farmerId}_g1',
      type: CropActivityType.growthMonitoring,
      title: 'Growth Monitoring Visit'.tr,
      plannedDate: seedToday.subtract(const Duration(days: 2)),
      detail: 'Review crop health and water levels.',
      status: statusFor(CropActivityType.growthMonitoring),
    ),
    CropPlanActivity(
      id: '${farmerId}_i1',
      type: CropActivityType.inputApplication,
      title: 'Input Application'.tr,
      plannedDate: seedToday.add(const Duration(days: 1)),
      detail: 'Apply the recommended input package.',
      status: statusFor(CropActivityType.inputApplication),
    ),
    CropPlanActivity(
      id: '${farmerId}_h1',
      type: CropActivityType.harvestWindowStart,
      title: 'Harvest Window Start'.tr,
      plannedDate: stage == FarmerStage.harvest
          ? seedToday
          : seedToday.add(const Duration(days: 3)),
      detail: 'Harvest date becomes selectable in procurement.',
      status: statusFor(CropActivityType.harvestWindowStart),
    ),
    CropPlanActivity(
      id: '${farmerId}_h2',
      type: CropActivityType.harvestWindowEnd,
      title: 'Harvest Window End'.tr,
      plannedDate: seedToday.add(const Duration(days: 7)),
      detail: 'Complete harvest before this date to preserve quality.',
      status: statusFor(CropActivityType.harvestWindowEnd),
    ),
  ];
}

WorkflowSnapshot buildSeededWorkflowSnapshot({DateTime? today}) {
  final seedToday = _dateOnly(today ?? DateTime.now());
  final preview = defaultSupportPreview();

  FarmerProfile farmer({
    required String id,
    required String name,
    required String phone,
    required String location,
    PlotLocation? plotLocation,
    required double acres,
    required FarmerStatus status,
    required FarmerStage stage,
    required String crop,
    required String season,
    required String landDetails,
  }) {
    return FarmerProfile(
      id: id,
      name: name,
      phone: phone,
      location: location,
      lands: [
        LandRecord(
          id: '${id}_land_1',
          crop: crop,
          season: season,
          totalAcres: acres,
          nurseryAcres: acres * 0.35,
          mainAcres: acres * 0.65,
          details: landDetails,
          plotLocation: plotLocation,
        )
      ],
      status: status,
      stage: stage,
      supportPreview: Map<String, String>.from(preview),
    );
  }

  final farmers = [
    farmer(
      id: 'anita-devi',
      name: 'Anita Devi',
      phone: '+91 9876543210',
      location: 'Bhaluka, Mymensingh',
      acres: 12,
      status: FarmerStatus.willing,
      stage: FarmerStage.willing,
      crop: 'Rice',
      season: 'Kharif 2026',
      landDetails: 'Village nursery plot and 8-acre main field.',
    ),
    farmer(
      id: 'parul-begum',
      name: 'Parul Begum',
      phone: '+91 9876500011',
      location: 'Karimpur',
      acres: 9,
      status: FarmerStatus.willing,
      stage: FarmerStage.willing,
      crop: 'Rice',
      season: 'Kharif 2026',
      landDetails: 'Leased field near canal; 3-acre nursery patch.',
    ),
    farmer(
      id: 'ravi-kumar',
      name: 'Ravi Kumar',
      phone: '+91 9876500022',
      location: 'Trishal',
      acres: 25,
      status: FarmerStatus.booked,
      stage: FarmerStage.booked,
      crop: 'Rice',
      season: 'Kharif 2026',
      landDetails: 'Primary plot beside collection point.',
    ),
    farmer(
      id: 'meera-sen',
      name: 'Meera Sen',
      phone: '+91 9876500033',
      location: 'Fulbaria',
      acres: 14,
      status: FarmerStatus.booked,
      stage: FarmerStage.growth,
      crop: 'Tomato',
      season: 'Summer 2026',
      landDetails: 'Drip irrigation line on 14-acre plot.',
    ),
    farmer(
      id: 'amit-kumar',
      name: 'Amit Kumar',
      phone: '+91 9876500044',
      location: 'Karimpur',
      acres: 18,
      status: FarmerStatus.booked,
      stage: FarmerStage.harvest,
      crop: 'Rice',
      season: 'Kharif 2026',
      landDetails: 'Harvest-ready parcel near paved road.',
    ),
    farmer(
      id: 'suresh-patel',
      name: 'Suresh Patel',
      phone: '+91 9876500055',
      location: 'Narayanganj',
      acres: 22,
      status: FarmerStatus.booked,
      stage: FarmerStage.settlementCompleted,
      crop: 'Chilli',
      season: 'Summer 2026',
      landDetails: 'Two adjacent irrigated plots.',
    ),
  ];

  final activities = <String, List<CropPlanActivity>>{
    for (final item in farmers)
      item.id: buildCropPlanActivities(
        farmerId: item.id,
        stage: item.stage,
        today: seedToday,
      ),
  };

  final support = <String, List<SupportRecord>>{
    'ravi-kumar': [
      SupportRecord(
        id: 'cash_ravi_1',
        type: SupportType.cash,
        farmerId: 'ravi-kumar',
        farmerName: 'Ravi Kumar',
        landDetails: 'Primary plot beside collection point.',
        cropContext: 'Rice / Kharif 2026',
        cashAmount: 60000,
        disbursementDate: seedToday.subtract(const Duration(days: 6)),
        confirmationCode: '4821',
        cashStage: CashSupportStage.acknowledged,
        otpVerified: true,
        createdAt: seedToday.subtract(const Duration(days: 7)),
        updatedAt: seedToday.subtract(const Duration(days: 6)),
      ),
    ],
    'meera-sen': [
      SupportRecord(
        id: 'kind_meera_1',
        type: SupportType.kind,
        farmerId: 'meera-sen',
        farmerName: 'Meera Sen',
        landDetails: 'Drip irrigation line on 14-acre plot.',
        cropContext: 'Tomato / Summer 2026',
        itemName: 'Fertilizer',
        quantity: 8,
        unit: 'bags',
        kindValue: 14000,
        disbursementDate: seedToday.subtract(const Duration(days: 2)),
        confirmationCode: '6215',
        kindStage: KindSupportStage.acknowledged,
        otpVerified: true,
        createdAt: seedToday.subtract(const Duration(days: 2)),
        updatedAt: seedToday.subtract(const Duration(days: 2)),
      ),
    ],
    'amit-kumar': [
      SupportRecord(
        id: 'cash_amit_1',
        type: SupportType.cash,
        farmerId: 'amit-kumar',
        farmerName: 'Amit Kumar',
        landDetails: 'Harvest-ready parcel near paved road.',
        cropContext: 'Rice / Kharif 2026',
        cashAmount: 50000,
        disbursementDate: seedToday.subtract(const Duration(days: 1)),
        confirmationCode: '1184',
        cashStage: CashSupportStage.paid,
        otpVerified: false,
        createdAt: seedToday.subtract(const Duration(days: 2)),
        updatedAt: seedToday.subtract(const Duration(hours: 10)),
      ),
    ],
    'suresh-patel': [
      SupportRecord(
        id: 'cash_suresh_1',
        type: SupportType.cash,
        farmerId: 'suresh-patel',
        farmerName: 'Suresh Patel',
        landDetails: 'Two adjacent irrigated plots.',
        cropContext: 'Chilli / Summer 2026',
        cashAmount: 45000,
        disbursementDate: seedToday.subtract(const Duration(days: 25)),
        confirmationCode: '9034',
        cashStage: CashSupportStage.acknowledged,
        otpVerified: true,
        finalized: true,
        createdAt: seedToday.subtract(const Duration(days: 26)),
        updatedAt: seedToday.subtract(const Duration(days: 25)),
      ),
    ],
  };

  final procurement = <String, List<ProcurementRecord>>{
    'amit-kumar': [
      ProcurementRecord(
        id: 'proc_amit_1',
        farmerId: 'amit-kumar',
        farmerName: 'Amit Kumar',
        crop: 'Rice',
        createdAt: seedToday.subtract(const Duration(days: 1)),
        updatedAt: seedToday.subtract(const Duration(hours: 2)),
        harvestDateOptions: [
          seedToday,
          seedToday.add(const Duration(days: 1)),
        ],
        selectedHarvestDate: seedToday,
        quantityHarvestedKg: 430,
        packagingDone: true,
        packagingDate: seedToday,
        packagingNotes: 'Packaging completed at field edge.',
        weighingDone: true,
        weighingDate: seedToday,
        finalWeighingQtyKg: 425,
        weighingNotes: 'Weighed at collection point.',
        ratePerKg: 44,
        receiptGenerated: true,
        receiptNumber: 'REC-1007',
        receiptMessage: 'Please keep this receipt for settlement.',
        transportAssigned: false,
        submitted: false,
      ),
    ],
    'suresh-patel': [
      ProcurementRecord(
        id: 'proc_suresh_1',
        farmerId: 'suresh-patel',
        farmerName: 'Suresh Patel',
        crop: 'Chilli',
        createdAt: seedToday.subtract(const Duration(days: 10)),
        updatedAt: seedToday.subtract(const Duration(days: 9)),
        harvestDateOptions: [
          seedToday.subtract(const Duration(days: 10)),
        ],
        selectedHarvestDate: seedToday.subtract(const Duration(days: 10)),
        quantityHarvestedKg: 520,
        packagingDone: true,
        packagingDate: seedToday.subtract(const Duration(days: 10)),
        packagingNotes: 'Packed in 25kg crates.',
        weighingDone: true,
        weighingDate: seedToday.subtract(const Duration(days: 10)),
        finalWeighingQtyKg: 508,
        weighingNotes: 'Final weigh completed at hub.',
        ratePerKg: 52,
        receiptGenerated: true,
        receiptNumber: 'REC-0951',
        receiptMessage: 'Completed and shared.',
        transportAssigned: true,
        transportDate: seedToday.subtract(const Duration(days: 9)),
        carrierNumber: 'TRK-5582',
        transporterName: 'Ramesh Das',
        carrierCapacity: 5.5,
        transportNotes: 'Delivered to cold storage.',
        submitted: true,
      ),
    ],
  };

  final settlements = <String, SettlementRecord>{
    'suresh-patel': SettlementRecord(
      id: 'set_suresh_1',
      farmerId: 'suresh-patel',
      farmerName: 'Suresh Patel',
      supportValue: 45000,
      procurementValue: 26416,
      netSettlement: -18584,
      status: SettlementStatus.completed,
      completedAt: seedToday.subtract(const Duration(days: 8)),
      notes: 'Reconciled against earlier support and transport adjustments.',
    ),
  };

  return WorkflowSnapshot(
    farmers: farmers,
    activities: activities,
    support: support,
    procurement: procurement,
    settlements: settlements,
  );
}

class WorkflowSnapshot {
  const WorkflowSnapshot({
    required this.farmers,
    required this.activities,
    required this.support,
    required this.procurement,
    required this.settlements,
  });

  final List<FarmerProfile> farmers;
  final Map<String, List<CropPlanActivity>> activities;
  final Map<String, List<SupportRecord>> support;
  final Map<String, List<ProcurementRecord>> procurement;
  final Map<String, SettlementRecord> settlements;

  Map<String, dynamic> toJson() {
    return {
      'version': _snapshotVersion,
      'farmers': farmers.map(_farmerToJson).toList(),
      'activities': activities.map(
        (key, value) => MapEntry(
          key,
          value.map(_activityToJson).toList(),
        ),
      ),
      'support': support.map(
        (key, value) => MapEntry(
          key,
          value.map(_supportRecordToJson).toList(),
        ),
      ),
      'procurement': procurement.map(
        (key, value) => MapEntry(
          key,
          value.map(_procurementRecordToJson).toList(),
        ),
      ),
      'settlements': settlements.map(
        (key, value) => MapEntry(key, _settlementToJson(value)),
      ),
    };
  }

  factory WorkflowSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != _snapshotVersion) {
      throw const FormatException('Unsupported workflow snapshot version.');
    }

    return WorkflowSnapshot(
      farmers: (json['farmers'] as List<dynamic>? ?? const [])
          .map((item) => _farmerFromJson(item as Map<String, dynamic>))
          .toList(),
      activities: _decodeMapOfLists(
        json['activities'],
        _activityFromJson,
      ),
      support: _decodeMapOfLists(
        json['support'],
        _supportRecordFromJson,
      ),
      procurement: _decodeMapOfLists(
        json['procurement'],
        _procurementRecordFromJson,
      ),
      settlements:
          (json['settlements'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(
          key,
          _settlementFromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class MemoryWorkflowRepository implements WorkflowRepository {
  MemoryWorkflowRepository({required WorkflowSnapshot snapshot})
      : _farmers = List<FarmerProfile>.of(snapshot.farmers),
        _activities = _copyListMap(snapshot.activities),
        _support = _copyListMap(snapshot.support),
        _procurement = _copyListMap(snapshot.procurement),
        _settlements = Map<String, SettlementRecord>.from(snapshot.settlements);

  final List<FarmerProfile> _farmers;
  final Map<String, List<CropPlanActivity>> _activities;
  final Map<String, List<SupportRecord>> _support;
  final Map<String, List<ProcurementRecord>> _procurement;
  final Map<String, SettlementRecord> _settlements;

  WorkflowSnapshot get snapshot => WorkflowSnapshot(
        farmers: List<FarmerProfile>.of(_farmers),
        activities: _copyListMap(_activities),
        support: _copyListMap(_support),
        procurement: _copyListMap(_procurement),
        settlements: Map<String, SettlementRecord>.from(_settlements),
      );

  @protected
  void onChanged() {}

  @override
  List<FarmerProfile> get farmers => List.unmodifiable(_farmers);

  @override
  List<CropPlanActivity> activitiesFor(String farmerId) =>
      List.unmodifiable(_activities[farmerId] ?? const []);

  @override
  List<SupportRecord> supportFor(String farmerId) =>
      List.unmodifiable(_support[farmerId] ?? const []);

  @override
  List<ProcurementRecord> procurementFor(String farmerId) =>
      List.unmodifiable(_procurement[farmerId] ?? const []);

  @override
  SettlementRecord? settlementFor(String farmerId) => _settlements[farmerId];

  @override
  FarmerProfile farmerById(String farmerId) =>
      _farmers.firstWhere((item) => item.id == farmerId);

  @override
  SupportRecord? supportById(String recordId) {
    for (final values in _support.values) {
      for (final item in values) {
        if (item.id == recordId) {
          return item;
        }
      }
    }
    return null;
  }

  @override
  ProcurementRecord? procurementById(String recordId) {
    for (final values in _procurement.values) {
      for (final item in values) {
        if (item.id == recordId) {
          return item;
        }
      }
    }
    return null;
  }

  @override
  void saveFarmer(FarmerProfile farmer) {
    final index = _farmers.indexWhere((item) => item.id == farmer.id);
    if (index == -1) {
      _farmers.add(farmer);
    } else {
      _farmers[index] = farmer;
    }
    onChanged();
  }

  @override
  void saveActivities(String farmerId, List<CropPlanActivity> activities) {
    _activities[farmerId] = List<CropPlanActivity>.of(activities);
    onChanged();
  }

  @override
  void saveSupport(SupportRecord record) {
    final records =
        List<SupportRecord>.of(_support[record.farmerId] ?? const []);
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    _support[record.farmerId] = records;
    onChanged();
  }

  @override
  void saveProcurement(ProcurementRecord record) {
    final records =
        List<ProcurementRecord>.of(_procurement[record.farmerId] ?? const []);
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    _procurement[record.farmerId] = records;
    onChanged();
  }

  @override
  void saveSettlement(SettlementRecord record) {
    _settlements[record.farmerId] = record;
    onChanged();
  }
}

class SeededWorkflowRepository extends MemoryWorkflowRepository {
  SeededWorkflowRepository._({required super.snapshot});

  factory SeededWorkflowRepository.seeded({DateTime? today}) {
    return SeededWorkflowRepository._(
      snapshot: buildSeededWorkflowSnapshot(today: today),
    );
  }
}

class PersistedWorkflowRepository extends MemoryWorkflowRepository {
  PersistedWorkflowRepository._({
    required super.snapshot,
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const storageKey = 'workflow_snapshot_v1';

  final SharedPreferences _preferences;
  Future<void> _pendingWrites = Future<void>.value();

  static Future<PersistedWorkflowRepository> create({
    DateTime? today,
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final fallback = buildSeededWorkflowSnapshot(today: today);
    final raw = prefs.getString(storageKey);

    WorkflowSnapshot snapshot = fallback;
    var shouldReseed = raw == null;
    if (raw != null) {
      try {
        snapshot = WorkflowSnapshot.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } on FormatException {
        shouldReseed = true;
      } on TypeError {
        shouldReseed = true;
      }
    }

    final repository = PersistedWorkflowRepository._(
      snapshot: snapshot,
      preferences: prefs,
    );

    if (shouldReseed) {
      repository._schedulePersist();
    }

    return repository;
  }

  Future<void> get pendingWrites => _pendingWrites;

  @override
  void onChanged() {
    _schedulePersist();
  }

  void _schedulePersist() {
    _pendingWrites = _pendingWrites.then((_) async {
      await _preferences.setString(
        storageKey,
        jsonEncode(snapshot.toJson()),
      );
    });
    unawaited(_pendingWrites);
  }
}

const _snapshotVersion = 1;

DateTime _dateOnly(DateTime value) => DateTime(
      value.year,
      value.month,
      value.day,
    );

Map<String, List<T>> _copyListMap<T>(Map<String, List<T>> source) => source.map(
      (key, value) => MapEntry(key, List<T>.of(value)),
    );

Map<String, List<T>> _decodeMapOfLists<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) decoder,
) {
  return (raw as Map<String, dynamic>? ?? const {}).map(
    (key, value) => MapEntry(
      key,
      (value as List<dynamic>? ?? const [])
          .map((item) => decoder(item as Map<String, dynamic>))
          .toList(),
    ),
  );
}

Map<String, dynamic> _farmerToJson(FarmerProfile farmer) {
  return {
    'id': farmer.id,
    'name': farmer.name,
    'phone': farmer.phone,
    'location': farmer.location,
    'lands': farmer.lands.map(_landRecordToJson).toList(),
    'status': farmer.status.name,
    'stage': farmer.stage.name,
    'supportPreview': farmer.supportPreview,
  };
}

FarmerProfile _farmerFromJson(Map<String, dynamic> json) {
  return FarmerProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    location: json['location'] as String,
    lands: (json['lands'] as List<dynamic>? ?? const [])
        .map((e) => _landRecordFromJson(e as Map<String, dynamic>))
        .toList(),
    status: FarmerStatus.values.byName(json['status'] as String),
    stage: FarmerStage.values.byName(json['stage'] as String),
    supportPreview: Map<String, String>.from(
      json['supportPreview'] as Map<String, dynamic>? ?? const {},
    ),
  );
}

Map<String, dynamic> _landRecordToJson(LandRecord land) {
  return {
    'id': land.id,
    'crop': land.crop,
    'season': land.season,
    'totalAcres': land.totalAcres,
    'nurseryAcres': land.nurseryAcres,
    'mainAcres': land.mainAcres,
    'details': land.details,
    'plotLocation': land.plotLocation == null ? null : _plotLocationToJson(land.plotLocation!),
  };
}

LandRecord _landRecordFromJson(Map<String, dynamic> json) {
  return LandRecord(
    id: json['id'] as String,
    crop: json['crop'] as String,
    season: json['season'] as String,
    totalAcres: (json['totalAcres'] as num).toDouble(),
    nurseryAcres: (json['nurseryAcres'] as num).toDouble(),
    mainAcres: (json['mainAcres'] as num).toDouble(),
    details: json['details'] as String,
    plotLocation: _plotLocationFromJson(json['plotLocation'] as Map<String, dynamic>?),
  );
}


Map<String, dynamic> _plotLocationToJson(PlotLocation location) {
  return {
    'polygonPoints': location.polygonPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    'displayAddress': location.displayAddress,
    'capturedAt': location.capturedAt.toIso8601String(),
  };
}

PlotLocation? _plotLocationFromJson(Map<String, dynamic>? json) {
  if (json == null) {
    return null;
  }
  final pointsRaw = json['polygonPoints'] as List<dynamic>? ?? [];
  return PlotLocation(
    polygonPoints: pointsRaw.map((e) => PlotCoordinate((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble())).toList(),
    displayAddress: json['displayAddress'] as String?,
    capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

Map<String, dynamic> _activityToJson(CropPlanActivity activity) {
  return {
    'id': activity.id,
    'type': activity.type.name,
    'title': activity.title,
    'plannedDate': activity.plannedDate.toIso8601String(),
    'detail': activity.detail,
    'status': activity.status.name,
  };
}

CropPlanActivity _activityFromJson(Map<String, dynamic> json) {
  return CropPlanActivity(
    id: json['id'] as String,
    type: CropActivityType.values.byName(json['type'] as String),
    title: json['title'] as String,
    plannedDate: DateTime.parse(json['plannedDate'] as String),
    detail: json['detail'] as String,
    status: CropActivityStatus.values.byName(json['status'] as String),
  );
}

Map<String, dynamic> _supportRecordToJson(SupportRecord record) {
  return {
    'id': record.id,
    'type': record.type.name,
    'farmerId': record.farmerId,
    'farmerName': record.farmerName,
    'landDetails': record.landDetails,
    'cropContext': record.cropContext,
    'disbursementDate': record.disbursementDate.toIso8601String(),
    'createdAt': record.createdAt.toIso8601String(),
    'updatedAt': record.updatedAt.toIso8601String(),
    'cashAmount': record.cashAmount,
    'itemName': record.itemName,
    'quantity': record.quantity,
    'unit': record.unit,
    'kindValue': record.kindValue,
    'cashStage': record.cashStage?.name,
    'kindStage': record.kindStage?.name,
    'confirmationCode': record.confirmationCode,
    'enteredOtp': record.enteredOtp,
    'otpVerified': record.otpVerified,
    'finalized': record.finalized,
  };
}

SupportRecord _supportRecordFromJson(Map<String, dynamic> json) {
  return SupportRecord(
    id: json['id'] as String,
    type: SupportType.values.byName(json['type'] as String),
    farmerId: json['farmerId'] as String,
    farmerName: json['farmerName'] as String,
    landDetails: json['landDetails'] as String,
    cropContext: json['cropContext'] as String,
    disbursementDate: DateTime.parse(json['disbursementDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    cashAmount: (json['cashAmount'] as num?)?.toDouble(),
    itemName: json['itemName'] as String?,
    quantity: (json['quantity'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
    kindValue: (json['kindValue'] as num?)?.toDouble(),
    cashStage: json['cashStage'] == null
        ? null
        : CashSupportStage.values.byName(json['cashStage'] as String),
    kindStage: json['kindStage'] == null
        ? null
        : KindSupportStage.values.byName(json['kindStage'] as String),
    confirmationCode: json['confirmationCode'] as String?,
    enteredOtp: json['enteredOtp'] as String?,
    otpVerified: json['otpVerified'] as bool? ?? false,
    finalized: json['finalized'] as bool? ?? false,
  );
}

Map<String, dynamic> _procurementRecordToJson(ProcurementRecord record) {
  return {
    'id': record.id,
    'farmerId': record.farmerId,
    'farmerName': record.farmerName,
    'crop': record.crop,
    'createdAt': record.createdAt.toIso8601String(),
    'updatedAt': record.updatedAt.toIso8601String(),
    'harvestDateOptions': record.harvestDateOptions
        .map((item) => item.toIso8601String())
        .toList(),
    'selectedHarvestDate': record.selectedHarvestDate?.toIso8601String(),
    'harvestingTime': _timeOfDayToMinutes(record.harvestingTime),
    'quantityHarvestedKg': record.quantityHarvestedKg,
    'packagingDone': record.packagingDone,
    'packagingDate': record.packagingDate?.toIso8601String(),
    'packagingNotes': record.packagingNotes,
    'weighingDone': record.weighingDone,
    'weighingDate': record.weighingDate?.toIso8601String(),
    'finalWeighingQtyKg': record.finalWeighingQtyKg,
    'weighingNotes': record.weighingNotes,
    'ratePerKg': record.ratePerKg,
    'receiptGenerated': record.receiptGenerated,
    'receiptNumber': record.receiptNumber,
    'receiptMessage': record.receiptMessage,
    'transportAssigned': record.transportAssigned,
    'transportDate': record.transportDate?.toIso8601String(),
    'carrierNumber': record.carrierNumber,
    'transporterName': record.transporterName,
    'carrierCapacity': record.carrierCapacity,
    'transportNotes': record.transportNotes,
    'submitted': record.submitted,
  };
}

ProcurementRecord _procurementRecordFromJson(Map<String, dynamic> json) {
  return ProcurementRecord(
    id: json['id'] as String,
    farmerId: json['farmerId'] as String,
    farmerName: json['farmerName'] as String,
    crop: json['crop'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    harvestDateOptions:
        (json['harvestDateOptions'] as List<dynamic>? ?? const [])
            .map((item) => DateTime.parse(item as String))
            .toList(),
    selectedHarvestDate: json['selectedHarvestDate'] == null
        ? null
        : DateTime.parse(json['selectedHarvestDate'] as String),
    harvestingTime: _minutesToTimeOfDay(
      json['harvestingTime'] as int? ??
          _timeOfDayToMinutes(const TimeOfDay(hour: 8, minute: 0)),
    ),
    quantityHarvestedKg: (json['quantityHarvestedKg'] as num?)?.toDouble(),
    packagingDone: json['packagingDone'] as bool? ?? false,
    packagingDate: json['packagingDate'] == null
        ? null
        : DateTime.parse(json['packagingDate'] as String),
    packagingNotes: json['packagingNotes'] as String? ?? '',
    weighingDone: json['weighingDone'] as bool? ?? false,
    weighingDate: json['weighingDate'] == null
        ? null
        : DateTime.parse(json['weighingDate'] as String),
    finalWeighingQtyKg: (json['finalWeighingQtyKg'] as num?)?.toDouble(),
    weighingNotes: json['weighingNotes'] as String? ?? '',
    ratePerKg: (json['ratePerKg'] as num?)?.toDouble() ?? 42,
    receiptGenerated: json['receiptGenerated'] as bool? ?? false,
    receiptNumber: json['receiptNumber'] as String?,
    receiptMessage: json['receiptMessage'] as String? ?? '',
    transportAssigned: json['transportAssigned'] as bool? ?? false,
    transportDate: json['transportDate'] == null
        ? null
        : DateTime.parse(json['transportDate'] as String),
    carrierNumber: json['carrierNumber'] as String? ?? '',
    transporterName: json['transporterName'] as String? ?? '',
    carrierCapacity: (json['carrierCapacity'] as num?)?.toDouble() ?? 0.0,
    transportNotes: json['transportNotes'] as String? ?? '',
    submitted: json['submitted'] as bool? ?? false,
  );
}

Map<String, dynamic> _settlementToJson(SettlementRecord record) {
  return {
    'id': record.id,
    'farmerId': record.farmerId,
    'farmerName': record.farmerName,
    'supportValue': record.supportValue,
    'procurementValue': record.procurementValue,
    'netSettlement': record.netSettlement,
    'status': record.status.name,
    'completedAt': record.completedAt?.toIso8601String(),
    'notes': record.notes,
  };
}

SettlementRecord _settlementFromJson(Map<String, dynamic> json) {
  return SettlementRecord(
    id: json['id'] as String,
    farmerId: json['farmerId'] as String,
    farmerName: json['farmerName'] as String,
    supportValue: (json['supportValue'] as num).toDouble(),
    procurementValue: (json['procurementValue'] as num).toDouble(),
    netSettlement: (json['netSettlement'] as num).toDouble(),
    status: SettlementStatus.values.byName(json['status'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    notes: json['notes'] as String? ?? '',
  );
}

int _timeOfDayToMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

TimeOfDay _minutesToTimeOfDay(int value) {
  final normalized = value.clamp(0, 1439);
  return TimeOfDay(
    hour: normalized ~/ 60,
    minute: normalized % 60,
  );
}
