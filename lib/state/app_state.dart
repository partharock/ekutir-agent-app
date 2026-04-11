import 'package:flutter/material.dart';

import '../models/crop_plan.dart';
import '../models/farmer.dart';
import '../models/misa.dart';
import '../models/procurement.dart';
import '../models/settlement.dart';
import '../models/support.dart';
import '../services/device_action_service.dart';
import '../services/receipt_service.dart';
import 'workflow_repository.dart';

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

class FarmerTimelineEntry {
  const FarmerTimelineEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.detail,
    required this.statusLabel,
  });

  final String id;
  final DateTime date;
  final String title;
  final String detail;
  final String statusLabel;
}

class AppState extends ChangeNotifier {
  AppState({
    required this.agentName,
    required this.agentCrop,
    required this.currentSeason,
    required this.agentStatus,
    required this.today,
    required this.repository,
    required this.deviceActions,
    required this.receiptService,
    List<MisaMessage>? misaMessages,
    this.isAuthenticated = false,
  }) : _misaMessages = List<MisaMessage>.of(misaMessages ?? const []);

  factory AppState.seeded({
    WorkflowRepository? repository,
    DeviceActionService? deviceActions,
    ReceiptService? receiptService,
    DateTime? today,
  }) {
    final seedToday = _dateOnly(today ?? DateTime.now());
    return AppState(
      agentName: 'Ravi',
      agentCrop: 'Rice',
      currentSeason: 'Kharif 2026',
      agentStatus: 'Field operations active',
      today: seedToday,
      repository:
          repository ?? SeededWorkflowRepository.seeded(today: seedToday),
      deviceActions: deviceActions ?? PlatformDeviceActionService(),
      receiptService: receiptService ?? PdfReceiptService(),
      misaMessages: [
        MisaMessage(
          id: 'misa_welcome',
          author: MisaMessageAuthor.assistant,
          message:
              'Hi Ravi, I’m MISA - your Farming Assistant! Ask for today’s priorities, a farmer-specific next step, or settlement readiness.',
          timestamp: DateTime(
            seedToday.year,
            seedToday.month,
            seedToday.day,
            8,
          ),
        ),
      ],
    );
  }

  static Future<AppState> create({
    WorkflowRepository? repository,
    DeviceActionService? deviceActions,
    ReceiptService? receiptService,
    DateTime? today,
  }) async {
    final seedToday = _dateOnly(today ?? DateTime.now());
    return AppState(
      agentName: 'Ravi',
      agentCrop: 'Rice',
      currentSeason: 'Kharif 2026',
      agentStatus: 'Field operations active',
      today: seedToday,
      repository: repository ??
          await PersistedWorkflowRepository.create(today: seedToday),
      deviceActions: deviceActions ?? PlatformDeviceActionService(),
      receiptService: receiptService ?? PdfReceiptService(),
      misaMessages: [
        MisaMessage(
          id: 'misa_welcome',
          author: MisaMessageAuthor.assistant,
          message:
              'Hi Ravi, I’m MISA - your Farming Assistant! Ask for today’s priorities, a farmer-specific next step, or settlement readiness.',
          timestamp: DateTime(
            seedToday.year,
            seedToday.month,
            seedToday.day,
            8,
          ),
        ),
      ],
    );
  }

  final String agentName;
  final String agentCrop;
  final String currentSeason;
  final String agentStatus;
  final DateTime today;
  final WorkflowRepository repository;
  final DeviceActionService deviceActions;
  final ReceiptService receiptService;

  final List<MisaMessage> _misaMessages;

  bool isAuthenticated;
  String? pendingPhoneNumber;
  SupportFlowDraft? supportDraft;
  String? activeProcurementId;
  int procurementStepIndex = 0;
  SupportRecord? lastSupportTransaction;
  ProcurementRecord? lastProcurementReceipt;
  MisaMode misaMode = MisaMode.general;
  String? misaFarmerId;

  List<FarmerProfile> get farmers => List.unmodifiable(repository.farmers);

  List<FarmerProfile> get willingFarmers =>
      farmers.where((item) => item.status == FarmerStatus.willing).toList();

  List<FarmerProfile> get bookedFarmers =>
      farmers.where((item) => item.status == FarmerStatus.booked).toList();

  FarmerProfile farmerById(String id) => repository.farmerById(id);

  List<CropPlanActivity> activitiesFor(String farmerId) =>
      repository.activitiesFor(farmerId);

  List<SupportRecord> supportFor(String farmerId) =>
      repository.supportFor(farmerId);

  List<ProcurementRecord> procurementFor(String farmerId) =>
      repository.procurementFor(farmerId);

  SettlementRecord settlementPreviewFor(String farmerId) {
    final existing = repository.settlementFor(farmerId);
    if (existing != null) {
      return existing;
    }
    final farmer = farmerById(farmerId);
    final supportValue =
        supportFor(farmerId).where((item) => item.isAcknowledged).fold<double>(
              0,
              (value, item) => value + (item.cashAmount ?? item.kindValue ?? 0),
            );
    final procurementValue = procurementFor(farmerId)
        .where((item) => item.submitted)
        .fold<double>(0, (value, item) => value + item.totalAmount);
    return SettlementRecord(
      id: 'pending_$farmerId',
      farmerId: farmerId,
      farmerName: farmer.name,
      supportValue: supportValue,
      procurementValue: procurementValue,
      netSettlement: procurementValue - supportValue,
      status: SettlementStatus.pendingReconciliation,
    );
  }

  List<SupportRecord> get allSupportRecords =>
      farmers.expand((item) => supportFor(item.id)).toList()
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

  List<ProcurementRecord> get allProcurementRecords =>
      farmers.expand((item) => procurementFor(item.id)).toList()
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

  double get totalCashSupportValue => allSupportRecords.fold<double>(
        0,
        (value, item) => value + (item.cashAmount ?? 0),
      );

  double get totalKindSupportValue => allSupportRecords.fold<double>(
        0,
        (value, item) => value + (item.kindValue ?? 0),
      );

  List<SupportRecord> get otpPendingSupport =>
      allSupportRecords.where((item) => item.isOtpPending).toList();

  List<SupportRecord> pendingSupportFor(String farmerId) =>
      supportFor(farmerId).where((item) => !item.finalized).toList();

  List<SupportRecord> unresolvedSupportFor(String farmerId) =>
      supportFor(farmerId).where((item) => !item.isAcknowledged).toList();

  List<SupportRecord> finalizedSupportFor(String farmerId) =>
      supportFor(farmerId).where((item) => item.finalized).toList();

  List<FarmerProfile> searchFarmers(String query, {FarmerStatus? status}) {
    final normalized = query.trim().toLowerCase();
    return farmers.where((farmer) {
      final matchesStatus = status == null || farmer.status == status;
      final matchesQuery = normalized.isEmpty ||
          farmer.name.toLowerCase().contains(normalized) ||
          farmer.location.toLowerCase().contains(normalized) ||
          farmer.phone.toLowerCase().contains(normalized);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  String normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    final keepPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }
    return '${keepPlus ? '+' : ''}$digits';
  }

  bool isNormalizedPhoneAvailable(
    String phone, {
    String? excludingFarmerId,
  }) {
    final normalized = normalizePhoneNumber(phone);
    if (normalized.isEmpty) {
      return true;
    }
    return !farmers.any(
      (item) =>
          item.id != excludingFarmerId &&
          normalizePhoneNumber(item.phone) == normalized,
    );
  }

  String? validateNewFarmerDraft(NewFarmerDraft draft) {
    if (draft.name.trim().isEmpty ||
        draft.phone.trim().isEmpty ||
        draft.location.trim().isEmpty ||
        draft.crop.trim().isEmpty ||
        draft.season.trim().isEmpty ||
        draft.landDetails.trim().isEmpty) {
      return 'All farmer details are required.';
    }

    if (normalizePhoneNumber(draft.phone).isEmpty) {
      return 'Enter a valid phone number.';
    }

    if (!isNormalizedPhoneAvailable(draft.phone)) {
      return 'A farmer with this phone number already exists.';
    }

    if (draft.totalLandAcres <= 0 ||
        draft.nurseryLandAcres <= 0 ||
        draft.mainLandAcres <= 0) {
      return 'Land values must be greater than zero.';
    }

    final difference =
        (draft.totalLandAcres - draft.nurseryLandAcres - draft.mainLandAcres)
            .abs();
    if (difference > 0.001) {
      return 'Nursery and main land must add up to total land.';
    }

    return null;
  }

  FarmerProfile? addWillingFarmer(NewFarmerDraft draft) {
    final sanitized = draft.copyWith(
      name: draft.name.trim(),
      phone: normalizePhoneNumber(draft.phone),
      location: draft.location.trim(),
      plotLocation: draft.plotLocation?.copyWith(
        displayAddress: draft.plotLocation?.displayAddress?.trim(),
      ),
      crop: draft.crop.trim(),
      season: draft.season.trim(),
      landDetails: draft.landDetails.trim(),
    );

    final validationError = validateNewFarmerDraft(sanitized);
    if (validationError != null) {
      return null;
    }

    final farmer = FarmerProfile(
      id: _nextFarmerId(sanitized.name),
      name: sanitized.name,
      phone: sanitized.phone,
      location: sanitized.location,
      plotLocation: sanitized.plotLocation,
      totalLandAcres: sanitized.totalLandAcres,
      crop: sanitized.crop,
      season: sanitized.season,
      status: FarmerStatus.willing,
      stage: FarmerStage.willing,
      nurseryLandAcres: sanitized.nurseryLandAcres,
      mainLandAcres: sanitized.mainLandAcres,
      landDetails: sanitized.landDetails,
      supportPreview: defaultSupportPreview(),
    );

    repository.saveFarmer(farmer);
    repository.saveActivities(
      farmer.id,
      buildCropPlanActivities(
        farmerId: farmer.id,
        stage: farmer.stage,
        today: today,
      ),
    );
    notifyListeners();
    return farmer;
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

  double get totalLandAcres => farmers.fold<double>(
        0,
        (value, farmer) => value + farmer.totalLandAcres,
      );

  int get tasksToday => homeTasks.length;
  int get willingCount => willingFarmers.length;
  int get bookedCount => bookedFarmers.length;
  int get nurseryCount =>
      farmers.where((item) => item.stage == FarmerStage.nursery).length;
  int get growthCount =>
      farmers.where((item) => item.stage == FarmerStage.growth).length;
  int get harvestCount =>
      farmers.where((item) => item.stage == FarmerStage.harvest).length;
  int get procurementCount =>
      farmers.where((item) => item.stage == FarmerStage.procurement).length;
  int get settlementCount => farmers
      .where((item) => item.stage == FarmerStage.settlementCompleted)
      .length;

  List<FarmerProfile> get priorityFarmers {
    final staged = List<FarmerProfile>.of(farmers);
    staged.sort((left, right) {
      final leftScore = _priorityScore(left);
      final rightScore = _priorityScore(right);
      if (leftScore != rightScore) {
        return leftScore.compareTo(rightScore);
      }
      return left.name.compareTo(right.name);
    });
    return staged;
  }

  int _priorityScore(FarmerProfile farmer) {
    if (settlementPreviewFor(farmer.id).status ==
            SettlementStatus.pendingReconciliation &&
        canCompleteSettlement(farmer.id)) {
      return 0;
    }
    if (supportFor(farmer.id).any((item) => item.isOtpPending)) {
      return 1;
    }
    if (procurementFor(farmer.id)
        .any((item) => !item.submitted && item.incompleteSteps.isNotEmpty)) {
      return 2;
    }
    if (_hasHarvestScheduledToday(farmer)) {
      return 3;
    }
    if (farmer.status == FarmerStatus.willing) {
      return 4;
    }
    switch (farmer.stage) {
      case FarmerStage.harvest:
        return 5;
      case FarmerStage.growth:
        return 6;
      case FarmerStage.nursery:
        return 7;
      case FarmerStage.booked:
        return 8;
      case FarmerStage.procurement:
        return 9;
      case FarmerStage.settlementCompleted:
        return 10;
      case FarmerStage.willing:
        return 11;
    }
  }

  List<TaskItem> get homeTasks {
    final tasks = priorityFarmers
        .map((farmer) => nextTaskForFarmer(farmer.id))
        .whereType<TaskItem>()
        .toList();
    tasks.sort((left, right) {
      final priorityCompare =
          left.priority.index.compareTo(right.priority.index);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return left.title.compareTo(right.title);
    });
    return tasks;
  }

  TaskItem? nextTaskForFarmer(String farmerId) {
    final farmer = farmerById(farmerId);
    final unresolvedSupport = unresolvedSupportFor(farmer.id);
    if (unresolvedSupport.isNotEmpty) {
      final record = unresolvedSupport.first;
      return TaskItem(
        id: 'support_${record.id}',
        title: '${record.farmerName} needs support follow-up',
        subtitle:
            '${record.type.label} is at ${record.statusLabel.toLowerCase()} status. Continue the exact disbursement step for this farmer.',
        priority: TaskPriority.high,
        statusLabel: record.statusLabel,
        actionLabel: 'Continue Support',
        route:
            '/support/flow/${record.type.name}?farmerId=${record.farmerId}&recordId=${record.id}',
      );
    }

    final procurementPending = procurementFor(farmer.id).where(
      (item) => !item.submitted && item.incompleteSteps.isNotEmpty,
    );
    if (procurementPending.isNotEmpty) {
      final record = procurementPending.first;
      final nextStep = record.incompleteSteps.first;
      return TaskItem(
        id: 'procurement_${record.id}',
        title: '${record.farmerName} has procurement pending',
        subtitle:
            '${nextStep.label} is the next incomplete procurement step for this farmer.',
        priority: TaskPriority.high,
        statusLabel: 'Procurement',
        actionLabel: 'Resume Procurement',
        route:
            '/harvest/procurement?farmerId=${record.farmerId}&recordId=${record.id}&step=${nextStep.name}',
      );
    }

    if (_hasHarvestScheduledToday(farmer)) {
      return TaskItem(
        id: 'harvest_${farmer.id}',
        title: '${farmer.name} is scheduled for harvest today',
        subtitle:
            'Open procurement for ${farmer.name} and capture the harvesting details from the crop plan date.',
        priority: TaskPriority.medium,
        statusLabel: 'Harvest',
        actionLabel: 'Open Harvest',
        route: '/harvest/procurement?farmerId=${farmer.id}',
      );
    }

    if (farmer.status == FarmerStatus.willing) {
      return TaskItem(
        id: 'booking_${farmer.id}',
        title: '${farmer.name} is waiting for booking',
        subtitle:
            'Start cash advance for ${farmer.name}. The farmer becomes booked only after OTP acknowledgment.',
        priority: TaskPriority.medium,
        statusLabel: 'Booking',
        actionLabel: 'Start Cash Advance',
        route: '/support/flow/cash?farmerId=${farmer.id}',
      );
    }

    if (canCompleteSettlement(farmer.id) &&
        settlementPreviewFor(farmer.id).status != SettlementStatus.completed) {
      return TaskItem(
        id: 'settlement_${farmer.id}',
        title: '${farmer.name} is ready for settlement',
        subtitle:
            'All support is acknowledged and procurement has been submitted. Complete reconciliation from the farmer profile.',
        priority: TaskPriority.low,
        statusLabel: 'Settlement',
        actionLabel: 'Open Profile',
        route: '/engage/farmer/${farmer.id}?tab=profile',
      );
    }

    return null;
  }

  SupportRecord? latestSupport(String farmerId, SupportType type) {
    for (final item in supportFor(farmerId)) {
      if (item.type == type) {
        return item;
      }
    }
    return null;
  }

  ProcurementRecord? latestProcurement(String farmerId) {
    final values = procurementFor(farmerId);
    return values.isEmpty ? null : values.first;
  }

  String farmerTrackerSupportLabel(String farmerId, SupportType type) {
    final item = latestSupport(farmerId, type);
    if (item == null) {
      return '${type.shortLabel}: Pending';
    }
    return '${type.shortLabel}: ${item.statusLabel}';
  }

  String farmerTrackerProcurementLabel(String farmerId) {
    final item = latestProcurement(farmerId);
    if (item == null) {
      return 'Procurement: Not started';
    }
    if (item.submitted) {
      return 'Procurement: Submitted';
    }
    if (item.incompleteSteps.isEmpty) {
      return 'Procurement: Ready to submit';
    }
    return 'Procurement: ${item.incompleteSteps.length} steps pending';
  }

  List<ProcurementStep> farmerTrackerProcurementSteps(String farmerId) {
    final item = latestProcurement(farmerId);
    if (item == null) {
      return const [];
    }
    if (item.submitted) {
      return const [];
    }
    return item.incompleteSteps;
  }

  List<FarmerTimelineEntry> timelineFor(String farmerId) {
    final entries = <FarmerTimelineEntry>[];
    for (final item in supportFor(farmerId)) {
      entries.add(
        FarmerTimelineEntry(
          id: item.id,
          date: item.updatedAt,
          title: item.type == SupportType.cash
              ? 'Cash support update'
              : 'Kind support update',
          detail: item.type == SupportType.cash
              ? 'Cash support is ${item.statusLabel.toLowerCase()}.'
              : '${item.itemName ?? 'Kind support'} is ${item.statusLabel.toLowerCase()}.',
          statusLabel: item.statusLabel,
        ),
      );
    }
    for (final item in procurementFor(farmerId)) {
      entries.add(
        FarmerTimelineEntry(
          id: item.id,
          date: item.updatedAt,
          title: item.submitted
              ? 'Procurement submitted'
              : 'Procurement in progress',
          detail: item.submitted
              ? 'Receipt ${item.receiptNumber ?? 'pending'} is ready for reconciliation.'
              : '${item.incompleteSteps.length} procurement steps still need capture.',
          statusLabel: item.submitted ? 'Submitted' : 'In Progress',
        ),
      );
    }
    for (final item in activitiesFor(farmerId)) {
      entries.add(
        FarmerTimelineEntry(
          id: item.id,
          date: item.plannedDate,
          title: item.title,
          detail: item.detail,
          statusLabel: item.status.label,
        ),
      );
    }
    final settlement = repository.settlementFor(farmerId);
    if (settlement != null) {
      entries.add(
        FarmerTimelineEntry(
          id: settlement.id,
          date: settlement.completedAt ?? today,
          title: 'Settlement ${settlement.status.label}',
          detail: settlement.notes.isEmpty
              ? 'Settlement total recorded as ₹${settlement.netSettlement.toStringAsFixed(0)}.'
              : settlement.notes,
          statusLabel: settlement.status.label,
        ),
      );
    }
    entries.sort((left, right) => right.date.compareTo(left.date));
    return entries;
  }

  void startSupportFlow(
    SupportType type, {
    String? farmerId,
    String? recordId,
  }) {
    final existing = recordId != null ? repository.supportById(recordId) : null;
    if (existing != null) {
      supportDraft = SupportFlowDraft(
        type: existing.type,
        stepIndex: _supportStepFor(existing),
        recordId: existing.id,
        farmerId: existing.farmerId,
        landDetails: existing.landDetails,
        cropContext: existing.cropContext,
        cashAmount: existing.cashAmount ?? 60000,
        disbursementDate: existing.disbursementDate,
        itemName: existing.itemName ?? 'Seeds',
        quantity: existing.quantity ?? 10,
        unit: existing.unit ?? 'kg',
        kindValue: existing.kindValue ?? 8000,
      );
    } else {
      final farmer = farmerId == null ? null : farmerById(farmerId);
      supportDraft = SupportFlowDraft(
        type: type,
        stepIndex: farmerId == null ? 0 : 1,
        farmerId: farmerId,
        landDetails: farmer?.landDetails ?? '',
        cropContext: farmer == null ? '' : '${farmer.crop} / ${farmer.season}',
        disbursementDate: today,
      );
    }
    notifyListeners();
  }

  int _supportStepFor(SupportRecord record) {
    if (record.type == SupportType.kind) {
      return 2;
    }
    switch (record.cashStage) {
      case CashSupportStage.booked:
      case null:
        return 2;
      case CashSupportStage.received:
        return 3;
      case CashSupportStage.paid:
      case CashSupportStage.acknowledged:
        return 4;
    }
  }

  SupportRecord? get activeSupportRecord => supportDraft?.recordId == null
      ? null
      : repository.supportById(supportDraft!.recordId!);

  void updateSupportDraft(SupportFlowDraft draft) {
    supportDraft = draft;
    notifyListeners();
  }

  void cancelSupportFlow() {
    supportDraft = null;
    notifyListeners();
  }

  bool saveSupportDetails() {
    final draft = supportDraft;
    if (draft == null || draft.farmerId == null) {
      return false;
    }
    final farmer = farmerById(draft.farmerId!);
    final now = _timestamp();
    final existing = activeSupportRecord;
    final code = existing?.confirmationCode ?? _generateCode();
    final record = SupportRecord(
      id: existing?.id ??
          '${draft.type.name}_${draft.farmerId}_${now.microsecondsSinceEpoch}',
      type: draft.type,
      farmerId: farmer.id,
      farmerName: farmer.name,
      landDetails: draft.landDetails,
      cropContext: draft.cropContext,
      disbursementDate: draft.disbursementDate,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      cashAmount: draft.type == SupportType.cash ? draft.cashAmount : null,
      itemName: draft.type == SupportType.kind ? draft.itemName : null,
      quantity: draft.type == SupportType.kind ? draft.quantity : null,
      unit: draft.type == SupportType.kind ? draft.unit : null,
      kindValue: draft.type == SupportType.kind ? draft.kindValue : null,
      cashStage: draft.type == SupportType.cash
          ? (existing?.cashStage ?? CashSupportStage.booked)
          : null,
      kindStage: draft.type == SupportType.kind
          ? (existing?.kindStage ?? KindSupportStage.given)
          : null,
      confirmationCode: code,
      enteredOtp: existing?.enteredOtp,
      otpVerified: existing?.otpVerified ?? false,
      finalized: existing?.finalized ?? false,
    );
    repository.saveSupport(record);
    lastSupportTransaction = record;
    supportDraft = draft.copyWith(
      recordId: record.id,
      stepIndex: draft.type == SupportType.cash ? 2 : 2,
    );
    notifyListeners();
    return true;
  }

  Future<bool> shareSupportCode() async {
    final record = activeSupportRecord;
    if (record == null || record.confirmationCode == null) {
      return false;
    }
    return deviceActions.shareText(
      subject: 'eK Acre confirmation code',
      text:
          'Farmer: ${record.farmerName}\nSupport: ${record.type.label}\nConfirmation code: ${record.confirmationCode}',
    );
  }

  bool markCashSupportReceived() {
    final record = activeSupportRecord;
    final draft = supportDraft;
    if (record == null || draft == null || record.type != SupportType.cash) {
      return false;
    }
    final updated = record.copyWith(
      cashStage: CashSupportStage.received,
      updatedAt: _timestamp(),
    );
    repository.saveSupport(updated);
    lastSupportTransaction = updated;
    supportDraft = draft.copyWith(stepIndex: 3);
    notifyListeners();
    return true;
  }

  bool markCashSupportPaid() {
    final record = activeSupportRecord;
    final draft = supportDraft;
    if (record == null || draft == null || record.type != SupportType.cash) {
      return false;
    }
    final updated = record.copyWith(
      cashStage: CashSupportStage.paid,
      updatedAt: _timestamp(),
    );
    repository.saveSupport(updated);
    lastSupportTransaction = updated;
    supportDraft = draft.copyWith(stepIndex: 4);
    notifyListeners();
    return true;
  }

  bool confirmSupportOtp() {
    final record = activeSupportRecord;
    final draft = supportDraft;
    if (record == null || draft == null) {
      return false;
    }
    if (draft.otpInput.trim() != record.confirmationCode) {
      return false;
    }
    final updated = record.copyWith(
      enteredOtp: draft.otpInput.trim(),
      otpVerified: true,
      cashStage: record.type == SupportType.cash
          ? CashSupportStage.acknowledged
          : record.cashStage,
      kindStage: record.type == SupportType.kind
          ? KindSupportStage.acknowledged
          : record.kindStage,
      updatedAt: _timestamp(),
    );
    repository.saveSupport(updated);
    lastSupportTransaction = updated;
    if (record.type == SupportType.cash) {
      final farmer = farmerById(record.farmerId);
      if (farmer.status == FarmerStatus.willing) {
        repository.saveFarmer(
          farmer.copyWith(
            status: FarmerStatus.booked,
            stage: FarmerStage.booked,
          ),
        );
      }
    }
    _reconcileFarmer(record.farmerId);
    notifyListeners();
    return true;
  }

  bool updateCropActivityStatus(
    String farmerId,
    String activityId,
    CropActivityStatus status,
  ) {
    final values = activitiesFor(farmerId)
        .map(
          (item) =>
              item.id == activityId ? item.copyWith(status: status) : item,
        )
        .toList();
    repository.saveActivities(farmerId, values);
    _reconcileFarmer(farmerId);
    notifyListeners();
    return true;
  }

  List<DateTime> harvestDateOptionsFor(String farmerId) {
    final dates = activitiesFor(farmerId)
        .where((item) => item.isHarvestWindow)
        .map((item) => DateTime(item.plannedDate.year, item.plannedDate.month,
            item.plannedDate.day))
        .toSet()
        .toList()
      ..sort();
    return dates;
  }

  void startProcurementFlow(
    String farmerId, {
    String? recordId,
    ProcurementStep? step,
  }) {
    ProcurementRecord? record;
    if (recordId != null) {
      record = repository.procurementById(recordId);
    } else {
      final existing =
          procurementFor(farmerId).where((item) => !item.submitted).toList();
      if (existing.isNotEmpty) {
        record = existing.first;
      }
    }

    final harvestDates = harvestDateOptionsFor(farmerId);

    if (record == null) {
      final farmer = farmerById(farmerId);
      record = ProcurementRecord(
        id: 'proc_${farmer.id}_${_timestamp().microsecondsSinceEpoch}',
        farmerId: farmer.id,
        farmerName: farmer.name,
        crop: farmer.crop,
        createdAt: _timestamp(),
        updatedAt: _timestamp(),
        harvestDateOptions: harvestDates,
        selectedHarvestDate:
            harvestDates.isNotEmpty ? harvestDates.first : null,
      );
      repository.saveProcurement(record);
    } else {
      record = record.copyWith(
        harvestDateOptions: harvestDates,
        selectedHarvestDate: harvestDates.contains(record.selectedHarvestDate)
            ? record.selectedHarvestDate
            : (harvestDates.isEmpty ? null : harvestDates.first),
      );
      repository.saveProcurement(record);
    }

    activeProcurementId = record.id;
    procurementStepIndex = step?.index ?? _resumeProcurementStep(record);
    notifyListeners();
  }

  ProcurementRecord? get activeProcurementRecord => activeProcurementId == null
      ? null
      : repository.procurementById(activeProcurementId!);

  int _resumeProcurementStep(ProcurementRecord record) {
    if (record.incompleteSteps.isEmpty) {
      return ProcurementStep.transport.index;
    }
    return record.incompleteSteps.first.index;
  }

  void updateProcurementDraft(ProcurementRecord record) {
    repository.saveProcurement(record.copyWith(updatedAt: _timestamp()));
    notifyListeners();
  }

  void setProcurementStep(int stepIndex) {
    procurementStepIndex = stepIndex;
    notifyListeners();
  }

  void cancelProcurementFlow() {
    activeProcurementId = null;
    procurementStepIndex = 0;
    notifyListeners();
  }

  bool submitProcurement() {
    final record = activeProcurementRecord;
    if (record == null || !record.isComplete) {
      return false;
    }
    final updated = record.copyWith(
      submitted: true,
      updatedAt: _timestamp(),
      receiptGenerated: true,
      receiptNumber: record.receiptNumber ??
          'REC-${1000 + procurementFor(record.farmerId).length}',
    );
    repository.saveProcurement(updated);
    lastProcurementReceipt = updated;
    _reconcileFarmer(record.farmerId);
    notifyListeners();
    return true;
  }

  bool canCompleteSettlement(String farmerId) {
    final supportRecords = supportFor(farmerId);
    final hasAcknowledgedSupport = supportRecords.isNotEmpty &&
        supportRecords.every((item) => item.isAcknowledged);
    final hasProcurement = procurementFor(farmerId)
        .any((item) => item.submitted && item.receiptGenerated);
    return hasAcknowledgedSupport && hasProcurement;
  }

  bool completeSettlement(String farmerId, {String notes = ''}) {
    if (!canCompleteSettlement(farmerId)) {
      return false;
    }
    final preview = settlementPreviewFor(farmerId);
    final completed = preview.copyWith(
      status: SettlementStatus.completed,
      completedAt: _timestamp(),
      notes: notes.isEmpty
          ? 'Settlement completed after reconciliation review.'
          : notes,
    );
    repository.saveSettlement(completed);
    for (final item
        in supportFor(farmerId).where((item) => item.isAcknowledged)) {
      repository
          .saveSupport(item.copyWith(finalized: true, updatedAt: _timestamp()));
    }
    _reconcileFarmer(farmerId);
    notifyListeners();
    return true;
  }

  void _reconcileFarmer(String farmerId) {
    final farmer = farmerById(farmerId);
    FarmerStage stage;
    final settlement = repository.settlementFor(farmerId);
    if (settlement?.status == SettlementStatus.completed) {
      stage = FarmerStage.settlementCompleted;
    } else if (procurementFor(farmerId).any((item) => item.submitted)) {
      stage = FarmerStage.procurement;
    } else if (farmer.status == FarmerStatus.willing) {
      stage = FarmerStage.willing;
    } else {
      final activities = activitiesFor(farmerId);
      final harvestStarted = activities.any(
        (item) =>
            item.type == CropActivityType.harvestWindowStart &&
            (item.status != CropActivityStatus.planned ||
                !_isAfterToday(item.plannedDate)),
      );
      final growthStarted = activities.any(
        (item) => item.type == CropActivityType.transplanting && item.completed,
      );
      final nurseryStarted = activities.any(
        (item) =>
            item.type == CropActivityType.nurseryStart &&
            item.status != CropActivityStatus.planned,
      );

      if (harvestStarted) {
        stage = FarmerStage.harvest;
      } else if (growthStarted) {
        stage = FarmerStage.growth;
      } else if (nurseryStarted) {
        stage = FarmerStage.nursery;
      } else {
        stage = FarmerStage.booked;
      }
    }

    repository.saveFarmer(farmer.copyWith(stage: stage));
  }

  bool _isAfterToday(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final current = DateTime(today.year, today.month, today.day);
    return normalized.isAfter(current);
  }

  bool _hasHarvestScheduledToday(FarmerProfile farmer) {
    final current = DateTime(today.year, today.month, today.day);
    return harvestDateOptionsFor(farmer.id).any((date) {
      final normalized = DateTime(date.year, date.month, date.day);
      return normalized == current;
    });
  }

  String _generateCode() {
    final seed = _timestamp().millisecond + _timestamp().second * 10;
    final code = 1000 + (seed % 9000);
    return '$code';
  }

  String _nextFarmerId(String name) {
    final words = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = words.isEmpty ? 'farmer' : words;
    var candidate = base;
    var suffix = 2;
    while (farmers.any((item) => item.id == candidate)) {
      candidate = '$base-$suffix';
      suffix += 1;
    }
    return candidate;
  }

  DateTime _timestamp() => DateTime.now();

  Future<bool> callFarmer(String farmerId) =>
      deviceActions.callPhone(farmerById(farmerId).phone);

  Future<bool> messageFarmer(String farmerId, {String? body}) =>
      deviceActions.sendSms(farmerById(farmerId).phone, body: body);

  Future<bool> openFarmerPlotLocation(String farmerId) {
    final farmer = farmerById(farmerId);
    final plotLocation = farmer.plotLocation;
    if (plotLocation == null) {
      return Future.value(false);
    }
    return deviceActions.openMapLocation(
      plotLocation,
      label: farmer.name,
    );
  }

  Future<bool> shareFarmerSummary(String farmerId) {
    final farmer = farmerById(farmerId);
    final settlement = settlementPreviewFor(farmerId);
    return deviceActions.shareText(
      subject: 'Farmer summary',
      text:
          '${farmer.name}\nStage: ${farmer.stage.label}\nCash: ${farmerTrackerSupportLabel(farmerId, SupportType.cash)}\nKind: ${farmerTrackerSupportLabel(farmerId, SupportType.kind)}\nSettlement: ${settlement.status.label}',
    );
  }

  Future<bool> shareProcurementReceipt(String procurementId) async {
    final record = repository.procurementById(procurementId);
    if (record == null) {
      return false;
    }
    final farmer = farmerById(record.farmerId);
    return receiptService.shareReceipt(farmer: farmer, record: record);
  }

  Future<bool> printProcurementReceipt(String procurementId) async {
    final record = repository.procurementById(procurementId);
    if (record == null) {
      return false;
    }
    final farmer = farmerById(record.farmerId);
    return receiptService.printReceipt(farmer: farmer, record: record);
  }

  void setMisaMode(MisaMode mode) {
    misaMode = mode;
    if (mode == MisaMode.general) {
      misaFarmerId = null;
    }
    notifyListeners();
  }

  void setMisaFarmer(String? farmerId) {
    misaFarmerId = farmerId;
    notifyListeners();
  }

  List<String> get misaSuggestedPrompts {
    if (misaMode == MisaMode.farmer) {
      return const [
        'What support is pending for this farmer?',
        'What is the next cultivation step?',
        'Is settlement ready?',
      ];
    }
    return const [
      'Who needs attention today?',
      'Which farmer is harvest ready?',
      'Show OTP pending support',
    ];
  }

  List<MisaMessage> get misaMessages => List.unmodifiable(_misaMessages);

  void submitMisaPrompt(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final now = _timestamp();
    _misaMessages.add(
      MisaMessage(
        id: 'misa_agent_${now.microsecondsSinceEpoch}',
        author: MisaMessageAuthor.agent,
        message: trimmed,
        timestamp: now,
      ),
    );
    _misaMessages.add(_buildMisaReply(trimmed, now));
    notifyListeners();
  }

  MisaMessage _buildMisaReply(String prompt, DateTime now) {
    if (misaMode == MisaMode.farmer && misaFarmerId == null) {
      return MisaMessage(
        id: 'misa_choose_farmer_${now.microsecondsSinceEpoch}',
        author: MisaMessageAuthor.assistant,
        message: 'Choose a farmer first to get farmer-specific guidance.',
        timestamp: now.add(const Duration(seconds: 1)),
      );
    }

    final farmer =
        misaFarmerId == null ? topPriorityFarmer : farmerById(misaFarmerId!);
    final recommendation = _buildRecommendation(prompt, farmer);
    return MisaMessage(
      id: 'misa_reply_${now.microsecondsSinceEpoch}',
      author: MisaMessageAuthor.assistant,
      message: recommendation.message,
      timestamp: now.add(const Duration(seconds: 1)),
      recommendation: recommendation,
    );
  }

  FarmerProfile get topPriorityFarmer => priorityFarmers.first;

  MisaRecommendation _buildRecommendation(String prompt, FarmerProfile farmer) {
    final lower = prompt.toLowerCase();
    final pendingSupport = supportFor(farmer.id).firstWhere(
      (item) => !item.isAcknowledged,
      orElse: () =>
          latestSupport(farmer.id, SupportType.cash) ??
          latestSupport(farmer.id, SupportType.kind) ??
          SupportRecord(
            id: 'temp',
            type: SupportType.cash,
            farmerId: farmer.id,
            farmerName: farmer.name,
            landDetails: farmer.landDetails,
            cropContext: '${farmer.crop} / ${farmer.season}',
            disbursementDate: today,
            createdAt: today,
            updatedAt: today,
            cashStage: CashSupportStage.booked,
          ),
    );

    if (lower.contains('otp') || lower.contains('support')) {
      final route =
          '/support/flow/${pendingSupport.type.name}?farmerId=${farmer.id}${pendingSupport.id == 'temp' ? '' : '&recordId=${pendingSupport.id}'}';
      final title =
          pendingSupport.id == 'temp' ? 'Start support' : 'Resume support';
      final message = pendingSupport.id == 'temp'
          ? '${farmer.name} does not have an active disbursement record yet. Start ${pendingSupport.type.shortLabel.toLowerCase()} support and capture the activation details.'
          : '${farmer.name} has ${pendingSupport.type.shortLabel.toLowerCase()} support at ${pendingSupport.statusLabel.toLowerCase()} status. Continue from the pending step and close OTP acknowledgement.';
      return MisaRecommendation(
        title: title,
        message: message,
        actionLabel: title,
        actionRoute: route,
        farmerId: farmer.id,
      );
    }

    if (lower.contains('settlement')) {
      final ready = canCompleteSettlement(farmer.id);
      return MisaRecommendation(
        title: ready ? 'Settlement ready' : 'Settlement pending',
        message: ready
            ? '${farmer.name} has acknowledged support and a submitted procurement record. Open the farmer profile and complete settlement.'
            : '${farmer.name} cannot reach settlement yet. Make sure support is acknowledged and procurement is submitted first.',
        actionLabel: 'Open profile',
        actionRoute: '/engage/farmer/${farmer.id}?tab=profile',
        farmerId: farmer.id,
      );
    }

    if (lower.contains('harvest') || lower.contains('procurement')) {
      final target = priorityFarmers.firstWhere(
        (item) =>
            item.stage == FarmerStage.harvest ||
            procurementFor(item.id).any((record) => !record.submitted),
        orElse: () => farmer,
      );
      return MisaRecommendation(
        title: 'Harvest next',
        message:
            '${target.name} is the best harvest candidate right now. Capture the remaining procurement steps and generate the receipt on the same visit.',
        actionLabel: 'Open harvest',
        actionRoute: '/harvest/procurement?farmerId=${target.id}',
        farmerId: target.id,
      );
    }

    if (lower.contains('cultivation') ||
        lower.contains('crop') ||
        lower.contains('next')) {
      final nextActivity = activitiesFor(farmer.id).firstWhere(
        (item) => item.status != CropActivityStatus.completed,
        orElse: () => activitiesFor(farmer.id).last,
      );
      return MisaRecommendation(
        title: 'Next cultivation step',
        message:
            '${farmer.name} should focus on "${nextActivity.title}" next. Update the crop plan activity once the field action is completed.',
        actionLabel: 'Open crop plan',
        actionRoute: '/crop-plan?farmerId=${farmer.id}',
        farmerId: farmer.id,
      );
    }

    final focus = topPriorityFarmer;
    return MisaRecommendation(
      title: 'Today’s first stop',
      message:
          'Visit ${focus.name} first. That farmer has the strongest mix of pending workflow work and field urgency today.',
      actionLabel: 'Open profile',
      actionRoute: '/engage/farmer/${focus.id}?tab=profile',
      farmerId: focus.id,
    );
  }
}

DateTime _dateOnly(DateTime value) => DateTime(
      value.year,
      value.month,
      value.day,
    );
