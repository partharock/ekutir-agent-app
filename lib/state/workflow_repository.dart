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

class SeededWorkflowRepository implements WorkflowRepository {
  SeededWorkflowRepository._({
    required List<FarmerProfile> farmers,
    required Map<String, List<CropPlanActivity>> activities,
    required Map<String, List<SupportRecord>> support,
    required Map<String, List<ProcurementRecord>> procurement,
    required Map<String, SettlementRecord> settlements,
  })  : _farmers = farmers,
        _activities = activities,
        _support = support,
        _procurement = procurement,
        _settlements = settlements;

  factory SeededWorkflowRepository.seeded({DateTime? today}) {
    final seedToday = _dateOnly(today ?? DateTime.now());

    FarmerProfile farmer({
      required String id,
      required String name,
      required String phone,
      required String location,
      required double acres,
      required FarmerStatus status,
      required FarmerStage stage,
      required String crop,
      required String season,
      required String landDetails,
      required Map<String, String> supportPreview,
    }) {
      return FarmerProfile(
        id: id,
        name: name,
        phone: phone,
        location: location,
        totalLandAcres: acres,
        crop: crop,
        season: season,
        status: status,
        stage: stage,
        nurseryLandAcres: acres * 0.35,
        mainLandAcres: acres * 0.65,
        landDetails: landDetails,
        supportPreview: supportPreview,
      );
    }

    List<CropPlanActivity> plan(String prefix, FarmerStage stage) {
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
          id: '${prefix}_n1',
          type: CropActivityType.nurseryStart,
          title: 'Nursery Start',
          plannedDate: seedToday.subtract(const Duration(days: 18)),
          detail: 'Prepare nursery bed and arrange saplings.',
          status: statusFor(CropActivityType.nurseryStart),
        ),
        CropPlanActivity(
          id: '${prefix}_t1',
          type: CropActivityType.transplanting,
          title: 'Transplanting',
          plannedDate: seedToday.subtract(const Duration(days: 8)),
          detail: 'Move nursery plants to the main field.',
          status: statusFor(CropActivityType.transplanting),
        ),
        CropPlanActivity(
          id: '${prefix}_g1',
          type: CropActivityType.growthMonitoring,
          title: 'Growth Monitoring Visit',
          plannedDate: seedToday.subtract(const Duration(days: 2)),
          detail: 'Review crop health and water levels.',
          status: statusFor(CropActivityType.growthMonitoring),
        ),
        CropPlanActivity(
          id: '${prefix}_i1',
          type: CropActivityType.inputApplication,
          title: 'Input Application',
          plannedDate: seedToday.add(const Duration(days: 1)),
          detail: 'Apply the recommended input package.',
          status: statusFor(CropActivityType.inputApplication),
        ),
        CropPlanActivity(
          id: '${prefix}_h1',
          type: CropActivityType.harvestWindowStart,
          title: 'Harvest Window Start',
          plannedDate: stage == FarmerStage.harvest
              ? seedToday
              : seedToday.add(const Duration(days: 3)),
          detail: 'Harvest date becomes selectable in procurement.',
          status: statusFor(CropActivityType.harvestWindowStart),
        ),
        CropPlanActivity(
          id: '${prefix}_h2',
          type: CropActivityType.harvestWindowEnd,
          title: 'Harvest Window End',
          plannedDate: seedToday.add(const Duration(days: 7)),
          detail: 'Complete harvest before this date to preserve quality.',
          status: statusFor(CropActivityType.harvestWindowEnd),
        ),
      ];
    }

    const preview = {
      'Cash Advance': 'Up to ₹60,000',
      'Seeds': '20 kg',
      'Fertilizer': '2 bags',
      'Pesticides': '5 bottles',
    };

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
        supportPreview: preview,
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
        supportPreview: preview,
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
        supportPreview: preview,
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
        supportPreview: preview,
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
        supportPreview: preview,
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
        supportPreview: preview,
      ),
    ];

    final activities = <String, List<CropPlanActivity>>{
      for (final item in farmers) item.id: plan(item.id, item.stage),
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
          driverName: 'Ramesh Das',
          driverPhone: '+91 9876503001',
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

    return SeededWorkflowRepository._(
      farmers: farmers,
      activities: activities,
      support: support,
      procurement: procurement,
      settlements: settlements,
    );
  }

  final List<FarmerProfile> _farmers;
  final Map<String, List<CropPlanActivity>> _activities;
  final Map<String, List<SupportRecord>> _support;
  final Map<String, List<ProcurementRecord>> _procurement;
  final Map<String, SettlementRecord> _settlements;

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
      return;
    }
    _farmers[index] = farmer;
  }

  @override
  void saveActivities(String farmerId, List<CropPlanActivity> activities) {
    _activities[farmerId] = activities;
  }

  @override
  void saveSupport(SupportRecord record) {
    final records = List<SupportRecord>.of(_support[record.farmerId] ?? const []);
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    _support[record.farmerId] = records;
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
  }

  @override
  void saveSettlement(SettlementRecord record) {
    _settlements[record.farmerId] = record;
  }
}

DateTime _dateOnly(DateTime value) => DateTime(
      value.year,
      value.month,
      value.day,
    );
