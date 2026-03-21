import 'package:flutter/material.dart';
import '../models/farmer.dart';
import '../models/support.dart';
import '../models/procurement.dart';
import '../models/crop_plan.dart';

enum TaskPriority { high, medium, low }

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.statusLabel,
    required this.actionLabel,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final TaskPriority priority;
  final String statusLabel;
  final String actionLabel;
  final String route;
}

class AppState extends ChangeNotifier {
  AppState({
    required this.agentName,
    required this.agentCrop,
    required this.currentSeason,
    required this.agentStatus,
    required List<FarmerProfile> farmers,
    this.isAuthenticated = false,
  }) : _farmers = farmers;

  factory AppState.seeded() {
    final today = DateTime(2026, 1, 25);

    FarmerProfile buildFarmer({
      required String id,
      required String name,
      required String phone,
      required String location,
      required double acres,
      required FarmerStatus status,
      required FarmerStage stage,
      required String crop,
      required List<CropPlanActivity> activities,
      required List<SupportTransaction> supportHistory,
      required List<ProcurementReceipt> procurementHistory,
    }) {
      return FarmerProfile(
        id: id,
        name: name,
        phone: phone,
        location: location,
        totalLandAcres: acres,
        crop: crop,
        season: 'Rabi 2026',
        status: status,
        stage: stage,
        nurseryLandAcres: acres * 0.35,
        mainLandAcres: acres * 0.65,
        cashEligibility: 100000,
        kindSupportItems: const {
          'Seeds': '20kg',
          'Fertilizer': '2 bags',
          'Pesticides': '5 bottles',
        },
        supportHistory: supportHistory,
        procurementHistory: procurementHistory,
        activities: activities,
      );
    }

    List<CropPlanActivity> cropActivities(String prefix) {
      return [
        CropPlanActivity(
          id: '${prefix}_a1',
          title: 'Nursery Setup',
          plannedDate: today.subtract(const Duration(days: 20)),
          detail: 'Seedlings prepared and nursery bed created.',
          status: 'Completed',
          completed: true,
        ),
        CropPlanActivity(
          id: '${prefix}_a2',
          title: 'Transplanting',
          plannedDate: today.subtract(const Duration(days: 12)),
          detail: 'Transplanting completed on schedule.',
          status: 'Completed',
          completed: true,
        ),
        CropPlanActivity(
          id: '${prefix}_a3',
          title: 'Growth Monitoring Visit',
          plannedDate: today.subtract(const Duration(days: 8)),
          detail: 'Crop health reviewed and notes captured.',
          status: 'Completed',
          completed: true,
        ),
        CropPlanActivity(
          id: '${prefix}_a4',
          title: 'Fertilizer Application (NPK)',
          plannedDate: today.add(const Duration(days: 5)),
          detail: 'Apply NPK 20:20:20 as per advisory.',
          status: 'In Progress',
          completed: false,
        ),
        CropPlanActivity(
          id: '${prefix}_a5',
          title: 'Harvest Window Start',
          plannedDate: today.add(const Duration(days: 12)),
          detail: 'Harvesting date option becomes available in procurement.',
          status: 'Planned',
          completed: false,
        ),
        CropPlanActivity(
          id: '${prefix}_a6',
          title: 'Harvest Window End',
          plannedDate: today.add(const Duration(days: 18)),
          detail: 'Harvest beyond this point may reduce quality.',
          status: 'Planned',
          completed: false,
        ),
      ];
    }

    final farmers = [
      buildFarmer(
        id: 'ravi-kumar',
        name: 'Ravi Kumar',
        phone: '01712-334455',
        location: 'Bhaluka, Mymensingh',
        acres: 25,
        status: FarmerStatus.booked,
        stage: FarmerStage.booked,
        crop: 'Rice',
        activities: cropActivities('ravi'),
        supportHistory: [
          SupportTransaction(
            id: 'support_1',
            type: SupportType.cash,
            farmerId: 'ravi-kumar',
            farmerName: 'Ravi Kumar',
            date: today.subtract(const Duration(days: 3)),
            statusLabel: 'Acknowledged',
            amount: 60000,
            purpose: 'Input Support',
            acknowledged: true,
          ),
        ],
        procurementHistory: [],
      ),
      buildFarmer(
        id: 'amit-kumar',
        name: 'Amit Kumar',
        phone: '+91 9876500000',
        location: 'Karimpur',
        acres: 25,
        status: FarmerStatus.booked,
        stage: FarmerStage.harvest,
        crop: 'Rice',
        activities: cropActivities('amit'),
        supportHistory: [
          SupportTransaction(
            id: 'support_2',
            type: SupportType.kind,
            farmerId: 'amit-kumar',
            farmerName: 'Amit Kumar',
            date: today.subtract(const Duration(days: 5)),
            statusLabel: 'Delivered',
            itemName: 'Fertilizer',
            purpose: 'Nutrient Support',
            acknowledged: true,
          ),
        ],
        procurementHistory: [
          ProcurementReceipt(
            id: 'receipt_old',
            farmerId: 'amit-kumar',
            farmerName: 'Amit Kumar',
            date: today.subtract(const Duration(days: 7)),
            harvestDateTime: today.subtract(const Duration(days: 7)),
            harvestedQtyKg: 340,
            finalQtyKg: 360,
            ratePerKg: 445,
            receiptNo: 'REC-10211',
            carrierNumber: 'TRK-3002',
            driverName: 'Jibon',
            transportNotes: 'Delivered to the district hub.',
            message: 'Previous procurement completed.',
          ),
        ],
      ),
      buildFarmer(
        id: 'anita-devi',
        name: 'Anita Devi',
        phone: '01798-552211',
        location: 'Muktagacha',
        acres: 20,
        status: FarmerStatus.willing,
        stage: FarmerStage.willing,
        crop: 'Rice',
        activities: cropActivities('anita'),
        supportHistory: [],
        procurementHistory: [],
      ),
      buildFarmer(
        id: 'bimal-das',
        name: 'Bimal Das',
        phone: '01988-110022',
        location: 'Trishal',
        acres: 30,
        status: FarmerStatus.willing,
        stage: FarmerStage.nursery,
        crop: 'Rice',
        activities: cropActivities('bimal'),
        supportHistory: [],
        procurementHistory: [],
      ),
    ];

    return AppState(
      agentName: 'Ravi Kumar',
      agentCrop: 'Rice',
      currentSeason: 'Kharif',
      agentStatus: 'In Progress',
      farmers: farmers,
    );
  }

  final String agentName;
  final String agentCrop;
  final String currentSeason;
  final String agentStatus;

  final List<FarmerProfile> _farmers;

  bool isAuthenticated;
  String? pendingPhoneNumber;
  SupportDraft? supportDraft;
  ProcurementDraft? procurementDraft;
  SupportTransaction? lastSupportTransaction;
  ProcurementReceipt? lastProcurementReceipt;

  List<FarmerProfile> get farmers => List.unmodifiable(_farmers);

  List<FarmerProfile> get willingFarmers =>
      _farmers
          .where((farmer) => farmer.status == FarmerStatus.willing)
          .toList();

  List<FarmerProfile> get bookedFarmers =>
      _farmers.where((farmer) => farmer.status == FarmerStatus.booked).toList();

  FarmerProfile get featuredFarmer =>
      bookedFarmers.isNotEmpty ? bookedFarmers.first : farmers.first;

  FarmerProfile farmerById(String id) {
    return _farmers.firstWhere((farmer) => farmer.id == id);
  }

  List<FarmerProfile> searchFarmers(String query, {FarmerStatus? status}) {
    final normalized = query.trim().toLowerCase();
    return _farmers.where((farmer) {
      final matchesStatus = status == null || farmer.status == status;
      final matchesQuery = normalized.isEmpty ||
          farmer.name.toLowerCase().contains(normalized) ||
          farmer.location.toLowerCase().contains(normalized) ||
          farmer.phone.toLowerCase().contains(normalized);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  void beginSignIn(String phoneNumber) {
    pendingPhoneNumber = phoneNumber;
    notifyListeners();
  }

  bool verifyOtp(String otp) {
    final isValid = RegExp(r'^\d{4}$').hasMatch(otp);
    if (isValid) {
      isAuthenticated = true;
      notifyListeners();
    }
    return isValid;
  }

  void bookFarmer(String farmerId) {
    final farmer = farmerById(farmerId);
    farmer.status = FarmerStatus.booked;
    if (farmer.stage == FarmerStage.willing) {
      farmer.stage = FarmerStage.booked;
    }
    notifyListeners();
  }

  void startSupportFlow(SupportType type) {
    supportDraft = SupportDraft(type: type, stepIndex: 0);
    notifyListeners();
  }

  void updateSupportDraft(SupportDraft draft) {
    supportDraft = draft;
    notifyListeners();
  }

  void cancelSupportFlow() {
    supportDraft = null;
    notifyListeners();
  }

  bool confirmSupportFlow() {
    final draft = supportDraft;
    if (draft == null || draft.farmerId == null) {
      return false;
    }

    final farmer = farmerById(draft.farmerId!);
    final transaction = SupportTransaction(
      id: 'support_${DateTime.now().millisecondsSinceEpoch}',
      type: draft.type,
      farmerId: farmer.id,
      farmerName: farmer.name,
      date: draft.date,
      statusLabel: draft.type == SupportType.cash
          ? 'Acknowledged'
          : 'Delivered',
      amount: draft.type == SupportType.cash ? draft.cashAmount : null,
      itemName: draft.type == SupportType.kind ? draft.itemName : null,
      purpose: draft.purpose,
      acknowledged: true,
    );

    farmer.supportHistory.insert(0, transaction);
    lastSupportTransaction = transaction;
    supportDraft = null;
    notifyListeners();
    return true;
  }

  void startProcurement(String farmerId) {
    procurementDraft = ProcurementDraft(farmerId: farmerId);
    notifyListeners();
  }

  void updateProcurementDraft(ProcurementDraft draft) {
    procurementDraft = draft;
    notifyListeners();
  }

  void cancelProcurementFlow() {
    procurementDraft = null;
    notifyListeners();
  }

  void saveProcurementDraft() {
    notifyListeners();
  }

  bool submitProcurement() {
    final draft = procurementDraft;
    if (draft == null) {
      return false;
    }

    final farmer = farmerById(draft.farmerId);
    final harvestDateTime = DateTime(
      draft.harvestingDate.year,
      draft.harvestingDate.month,
      draft.harvestingDate.day,
      draft.harvestingTime.hour,
      draft.harvestingTime.minute,
    );
    final receipt = ProcurementReceipt(
      id: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: farmer.id,
      farmerName: farmer.name,
      date: draft.transportDate,
      harvestDateTime: harvestDateTime,
      harvestedQtyKg: draft.quantityHarvestedKg,
      finalQtyKg: draft.finalWeighingQtyKg,
      ratePerKg: draft.ratePerKg,
      receiptNo: 'REC-${10000 + farmer.procurementHistory.length + 23}',
      carrierNumber: draft.carrierNumber,
      driverName: draft.driverName,
      transportNotes: draft.transportNotes,
      message: draft.receiptMessage,
    );

    farmer.procurementHistory.insert(0, receipt);
    farmer.stage = FarmerStage.procurement;
    lastProcurementReceipt = receipt;
    procurementDraft = null;
    notifyListeners();
    return true;
  }

  double get totalLandAcres =>
      _farmers.fold<double>(0, (value, farmer) => value + farmer.totalLandAcres);

  int get tasksToday => homeTasks.length;

  int get willingCount => willingFarmers.length;

  int get bookedCount => bookedFarmers.length;

  int get nurseryCount =>
      _farmers.where((farmer) => farmer.stage == FarmerStage.nursery).length;

  int get transplantedCount =>
      _farmers
          .where((farmer) =>
              farmer.stage == FarmerStage.transplanted ||
              farmer.stage == FarmerStage.growth)
          .length;

  int get harvestCount =>
      _farmers.where((farmer) => farmer.stage == FarmerStage.harvest).length;

  int get procurementCount =>
      _farmers
          .where((farmer) =>
              farmer.procurementHistory.isNotEmpty ||
              farmer.stage == FarmerStage.procurement)
          .length;

  List<TaskItem> get homeTasks => [
        TaskItem(
          id: 'task_1',
          title: 'OTP acknowledgement pending',
          subtitle: 'Cash support pending for Amit Kumar',
          priority: TaskPriority.high,
          statusLabel: 'Action Needed',
          actionLabel: 'Open',
          route: '/support',
        ),
        TaskItem(
          id: 'task_2',
          title: 'Kind support delivery pending',
          subtitle: 'Review support coverage for Ravi Kumar',
          priority: TaskPriority.low,
          statusLabel: 'Growth',
          actionLabel: 'Open',
          route: '/support',
        ),
        TaskItem(
          id: 'task_3',
          title: 'Harvest booking window open',
          subtitle: 'Start procurement for Amit Kumar',
          priority: TaskPriority.medium,
          statusLabel: 'Harvest',
          actionLabel: 'Open',
          route: '/harvest',
        ),
      ];
}
