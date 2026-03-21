import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const bool _debugAutoLogin = bool.fromEnvironment('AUTO_LOGIN');
const String _debugInitialRoute =
String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/');
const String _debugSupportFlow =
String.fromEnvironment('DEBUG_SUPPORT_FLOW', defaultValue: '');
const int _debugSupportStep =
int.fromEnvironment('DEBUG_SUPPORT_STEP', defaultValue: -1);
const int _debugProcurementStep =
int.fromEnvironment('DEBUG_PROCUREMENT_STEP', defaultValue: -1);

void main() {
  final appState = AppState.seeded();
  if (_debugAutoLogin) {
    appState.isAuthenticated = true;
  }
  _applyDebugSeed(appState);
  runApp(buildEkAcreGrowthApp(appState: appState));
}

void _applyDebugSeed(AppState appState) {
  if (_debugSupportFlow.isNotEmpty) {
    final type = _debugSupportFlow == 'kind'
        ? SupportType.kind
        : SupportType.cash;
    appState.startSupportFlow(type);
    if (appState.supportDraft != null) {
      appState.updateSupportDraft(
        appState.supportDraft!.copyWith(
          farmerId: appState.featuredFarmer.id,
          stepIndex: _debugSupportStep < 0 ? 0 : _debugSupportStep,
        ),
      );
    }
  }

  if (_debugProcurementStep >= 0) {
    appState.startProcurement(appState.featuredFarmer.id);
    if (appState.procurementDraft != null) {
      appState.updateProcurementDraft(
        appState.procurementDraft!.copyWith(stepIndex: _debugProcurementStep),
      );
    }
  }
}

Widget buildEkAcreGrowthApp({AppState? appState}) {
  final state = appState ?? AppState.seeded();
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: EkAcreGrowthApp(appState: state),
  );
}

class EkAcreGrowthApp extends StatefulWidget {
  const EkAcreGrowthApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<EkAcreGrowthApp> createState() => _EkAcreGrowthAppState();
}

class _EkAcreGrowthAppState extends State<EkAcreGrowthApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter(widget.appState);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'eK Acre Growth',
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}

GoRouter _createRouter(AppState appState) {
  return GoRouter(
    initialLocation: _debugInitialRoute,
    refreshListenable: appState,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/' || location == '/sign-in' || location == '/otp';

      if (!appState.isAuthenticated && !isAuthRoute) {
        return '/sign-in';
      }

      if (appState.isAuthenticated && location == '/sign-in') {
        return '/home';
      }

      if (appState.isAuthenticated && location == '/otp') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const PhoneSignInScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/engage',
            builder: (context, state) => const EngagementScreen(),
          ),
          GoRoute(
            path: '/engage/farmer/:farmerId',
            builder: (context, state) {
              return FarmerProfileScreen(
                farmerId: state.pathParameters['farmerId']!,
                initialTab: state.uri.queryParameters['tab'] ?? 'profile',
              );
            },
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/support/flow/:type',
            builder: (context, state) {
              final typeName = state.pathParameters['type']!;
              final type = SupportType.values.firstWhere(
                    (value) => value.name == typeName,
                orElse: () => SupportType.cash,
              );
              return SupportFlowScreen(type: type);
            },
          ),
          GoRoute(
            path: '/support/success',
            builder: (context, state) => const SupportSuccessScreen(),
          ),
          GoRoute(
            path: '/harvest',
            builder: (context, state) => const HarvestHubScreen(),
          ),
          GoRoute(
            path: '/harvest/procurement',
            builder: (context, state) => const ProcurementFlowScreen(),
          ),
          GoRoute(
            path: '/harvest/success',
            builder: (context, state) => const ProcurementSuccessScreen(),
          ),
          GoRoute(
            path: '/crop-plan',
            builder: (context, state) => const CropPlanScreen(),
          ),
          GoRoute(
            path: '/misa-ai',
            builder: (context, state) => const MisaAiPlaceholderScreen(),
          ),
        ],
      ),
    ],
  );
}

ThemeData buildAppTheme() {
  const brandGreen = AppColors.brandGreen;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: brandGreen).copyWith(
      primary: brandGreen,
      secondary: AppColors.brandBlue,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.pageBackground,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.pageBackground,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    dividerColor: AppColors.cardBorder,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class AppColors {
  static const Color brandGreen = Color(0xFF5F9800);
  static const Color brandGreenDark = Color(0xFF467300);
  static const Color brandGreenLight = Color(0xFFEAF6D9);
  static const Color brandBlue = Color(0xFF405DB5);
  static const Color brandBlueLight = Color(0xFFE7EEFF);
  static const Color pageBackground = Color(0xFFF8F9F5);
  static const Color textPrimary = Color(0xFF23252F);
  static const Color textSecondary = Color(0xFF6F7485);
  static const Color cardBorder = Color(0xFFE4E7EE);
  static const Color warning = Color(0xFFF59B23);
  static const Color danger = Color(0xFFD9534F);
  static const Color success = Color(0xFF4A9901);
}

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

enum SupportType { cash, kind }

enum ProcurementStep {
  harvesting,
  packaging,
  weighing,
  price,
  receipt,
  transport,
}

enum TaskPriority { high, medium, low }

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

extension SupportTypeX on SupportType {
  String get label =>
      this == SupportType.cash ? 'Cash Support' : 'Kind Support';

  String get shortLabel => this == SupportType.cash ? 'Cash' : 'Kind';

  IconData get icon =>
      this == SupportType.cash ? Icons.payments_outlined : Icons
          .inventory_2_outlined;
}

extension ProcurementStepX on ProcurementStep {
  String get label {
    switch (this) {
      case ProcurementStep.harvesting:
        return 'Harvesting';
      case ProcurementStep.packaging:
        return 'Packaging';
      case ProcurementStep.weighing:
        return 'Weighing';
      case ProcurementStep.price:
        return 'Price';
      case ProcurementStep.receipt:
        return 'Receipt';
      case ProcurementStep.transport:
        return 'Transport';
    }
  }
}

extension TaskPriorityX on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.brandBlue;
      case TaskPriority.low:
        return AppColors.brandGreen;
    }
  }
}

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

class SupportTransaction {
  SupportTransaction({
    required this.id,
    required this.type,
    required this.farmerId,
    required this.farmerName,
    required this.date,
    required this.statusLabel,
    this.amount,
    this.itemName,
    required this.purpose,
    required this.acknowledged,
  });

  final String id;
  final SupportType type;
  final String farmerId;
  final String farmerName;
  final DateTime date;
  final String statusLabel;
  final double? amount;
  final String? itemName;
  final String purpose;
  final bool acknowledged;
}

class ProcurementReceipt {
  ProcurementReceipt({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.date,
    required this.harvestDateTime,
    required this.harvestedQtyKg,
    required this.finalQtyKg,
    required this.ratePerKg,
    required this.receiptNo,
    required this.carrierNumber,
    required this.driverName,
    required this.transportNotes,
    this.message,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final DateTime date;
  final DateTime harvestDateTime;
  final double harvestedQtyKg;
  final double finalQtyKg;
  final double ratePerKg;
  final String receiptNo;
  final String carrierNumber;
  final String driverName;
  final String transportNotes;
  final String? message;

  double get totalAmount => finalQtyKg * ratePerKg;
}

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

class SupportDraft {
  SupportDraft({
    required this.type,
    required this.stepIndex,
    this.farmerId,
    this.cashAmount = 60000,
    this.itemName = 'Fertilizer',
    this.purpose = 'Input Support',
    DateTime? date,
  }) : date = date ?? DateTime(2026, 1, 25);

  final SupportType type;
  final int stepIndex;
  final String? farmerId;
  final double cashAmount;
  final String itemName;
  final String purpose;
  final DateTime date;

  SupportDraft copyWith({
    SupportType? type,
    int? stepIndex,
    String? farmerId,
    double? cashAmount,
    String? itemName,
    String? purpose,
    DateTime? date,
  }) {
    return SupportDraft(
      type: type ?? this.type,
      stepIndex: stepIndex ?? this.stepIndex,
      farmerId: farmerId ?? this.farmerId,
      cashAmount: cashAmount ?? this.cashAmount,
      itemName: itemName ?? this.itemName,
      purpose: purpose ?? this.purpose,
      date: date ?? this.date,
    );
  }
}

class ProcurementDraft {
  ProcurementDraft({
    required this.farmerId,
    this.stepIndex = 0,
    DateTime? harvestingDate,
    this.harvestingTime = const TimeOfDay(hour: 15, minute: 0),
    this.quantityHarvestedKg = 380,
    this.packagingStatus = 'Completed',
    DateTime? packagingDate,
    this.packagingNotes = 'Packed in 25kg crates.',
    DateTime? weighingDate,
    this.finalWeighingQtyKg = 420,
    this.weighingNotes = 'Packed and weighed at the field collection point.',
    this.ratePerKg = 450,
    this.receiptMessage = 'Share the receipt with the farmer after confirmation.',
    DateTime? transportDate,
    this.carrierNumber = 'TRK-5582',
    this.driverName = 'Name Surname',
    this.driverPhone = '02156-64456',
    this.transportNotes = 'Pickup from Trishal collection point.',
  })
      : harvestingDate = harvestingDate ?? DateTime(2026, 1, 25),
        packagingDate = packagingDate ?? DateTime(2026, 1, 25),
        weighingDate = weighingDate ?? DateTime(2026, 1, 25),
        transportDate = transportDate ?? DateTime(2026, 1, 25);

  final String farmerId;
  final int stepIndex;
  final DateTime harvestingDate;
  final TimeOfDay harvestingTime;
  final double quantityHarvestedKg;
  final String packagingStatus;
  final DateTime packagingDate;
  final String packagingNotes;
  final DateTime weighingDate;
  final double finalWeighingQtyKg;
  final String weighingNotes;
  final double ratePerKg;
  final String receiptMessage;
  final DateTime transportDate;
  final String carrierNumber;
  final String driverName;
  final String driverPhone;
  final String transportNotes;

  ProcurementDraft copyWith({
    String? farmerId,
    int? stepIndex,
    DateTime? harvestingDate,
    TimeOfDay? harvestingTime,
    double? quantityHarvestedKg,
    String? packagingStatus,
    DateTime? packagingDate,
    String? packagingNotes,
    DateTime? weighingDate,
    double? finalWeighingQtyKg,
    String? weighingNotes,
    double? ratePerKg,
    String? receiptMessage,
    DateTime? transportDate,
    String? carrierNumber,
    String? driverName,
    String? driverPhone,
    String? transportNotes,
  }) {
    return ProcurementDraft(
      farmerId: farmerId ?? this.farmerId,
      stepIndex: stepIndex ?? this.stepIndex,
      harvestingDate: harvestingDate ?? this.harvestingDate,
      harvestingTime: harvestingTime ?? this.harvestingTime,
      quantityHarvestedKg: quantityHarvestedKg ?? this.quantityHarvestedKg,
      packagingStatus: packagingStatus ?? this.packagingStatus,
      packagingDate: packagingDate ?? this.packagingDate,
      packagingNotes: packagingNotes ?? this.packagingNotes,
      weighingDate: weighingDate ?? this.weighingDate,
      finalWeighingQtyKg: finalWeighingQtyKg ?? this.finalWeighingQtyKg,
      weighingNotes: weighingNotes ?? this.weighingNotes,
      ratePerKg: ratePerKg ?? this.ratePerKg,
      receiptMessage: receiptMessage ?? this.receiptMessage,
      transportDate: transportDate ?? this.transportDate,
      carrierNumber: carrierNumber ?? this.carrierNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      transportNotes: transportNotes ?? this.transportNotes,
    );
  }
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
      id: 'support_${DateTime
          .now()
          .millisecondsSinceEpoch}',
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
      id: 'receipt_${DateTime
          .now()
          .millisecondsSinceEpoch}',
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
      _farmers.fold<double>(
          0, (value, farmer) => value + farmer.totalLandAcres);

  int get tasksToday => homeTasks.length;

  int get willingCount => willingFarmers.length;

  int get bookedCount => bookedFarmers.length;

  int get nurseryCount =>
      _farmers
          .where((farmer) => farmer.stage == FarmerStage.nursery)
          .length;

  int get transplantedCount =>
      _farmers
          .where((farmer) =>
      farmer.stage == FarmerStage.transplanted ||
          farmer.stage == FarmerStage.growth)
          .length;

  int get harvestCount =>
      _farmers
          .where((farmer) => farmer.stage == FarmerStage.harvest)
          .length;

  int get procurementCount =>
      _farmers
          .where((farmer) =>
      farmer.procurementHistory.isNotEmpty ||
          farmer.stage == FarmerStage.procurement)
          .length;

  List<TaskItem> get homeTasks =>
      [
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

enum AppTab { home, engage, support, harvest, cropPlan, misaAi }

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  AppTab get currentTab {
    if (location.startsWith('/engage')) {
      return AppTab.engage;
    }
    if (location.startsWith('/support')) {
      return AppTab.support;
    }
    if (location.startsWith('/harvest')) {
      return AppTab.harvest;
    }
    if (location.startsWith('/crop-plan')) {
      return AppTab.cropPlan;
    }
    if (location.startsWith('/misa-ai')) {
      return AppTab.misaAi;
    }
    return AppTab.home;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) {
          switch (AppTab.values[index]) {
            case AppTab.home:
              context.go('/home');
              break;
            case AppTab.engage:
              context.go('/engage');
              break;
            case AppTab.support:
              context.go('/support');
              break;
            case AppTab.harvest:
              context.go('/harvest');
              break;
            case AppTab.cropPlan:
              context.go('/crop-plan');
              break;
            case AppTab.misaAi:
              context.go('/misa-ai');
              break;
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.brandGreenLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: 'Engage',
          ),
          NavigationDestination(
            icon: Icon(Icons.monetization_on_outlined),
            selectedIcon: Icon(Icons.monetization_on),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: 'Harvest',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Crop Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'MISA AI',
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      final appState = context.read<AppState>();
      context.go(appState.isAuthenticated ? '/home' : '/sign-in');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      backgroundAssetPath: 'assets/reference/auth_splash_blur.png',
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                BrandMark(size: 54),
                SizedBox(height: 16),
                Text(
                  'eK Link',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'eK Acre Growth',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Partnership Farming',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _controller.text
        .trim()
        .length >= 10;

    return AuthBackground(
      backgroundAssetPath: 'assets/reference/auth_signin_blur.png',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 56)),
                    const SizedBox(height: 20),
                    Text(
                      'Sign In To Your Account',
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Phone Number *',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('phone_number_field'),
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: '+91   ',
                        hintText: 'Enter your phone number',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('send_otp_button'),
                      style: filledButtonStyle(),
                      onPressed: canContinue
                          ? () {
                        context
                            .read<AppState>()
                            .beginSignIn(_controller.text.trim());
                        context.push('/otp');
                      }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Send OTP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),)

    );

  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingPhone =
        context
            .watch<AppState>()
            .pendingPhoneNumber ?? 'XX XXXX 4331';
    final value = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');

    return AuthBackground(
      backgroundAssetPath: 'assets/reference/auth_signin_blur.png',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 56)),
                    const SizedBox(height: 20),
                    Text(
                      'Verify Your Account',
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OTP sent to +91 $pendingPhone',
                      textAlign: TextAlign.center,
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Stack(
                        children: [
                          Row(
                            children: List.generate(4, (index) {
                              final digit = index < value.length
                                  ? value[index]
                                  : '0';
                              return Expanded(
                                child: Container(
                                  height: 74,
                                  margin: EdgeInsets.only(
                                    right: index == 3 ? 0 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    digit,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.02,
                              child: TextField(
                                key: const Key('otp_field'),
                                controller: _controller,
                                focusNode: _focusNode,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                onChanged: (_) =>
                                    setState(() {
                                      _error = null;
                                    }),
                                decoration:
                                const InputDecoration(counterText: ''),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('submit_otp_button'),
                      style: filledButtonStyle(),
                      onPressed: () {
                        final success =
                        context.read<AppState>().verifyOtp(value);
                        if (success) {
                          context.go('/home');
                        } else {
                          setState(() {
                            _error =
                            'Enter any valid 4 digit OTP to continue.';
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Submit'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _error = 'Mock OTP resent. Use any 4 digits.';
                        });
                      },
                      child: const Text('Resend OTP'),
                    ),
                  ],

                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final trackerFarmers = appState.bookedFarmers.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brandGreenLight,
                  child: Icon(
                    Icons.person,
                    color: AppColors.brandGreenDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                      Text(
                        appState.agentName,
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      showMockSnackBar(
                        context,
                        'Notifications are mocked in v1.',
                      ),
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Portfolio',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  const InfoPair(label: 'Crop', value: 'Rice'),
                  const SizedBox(height: 10),
                  InfoPair(
                    label: 'Current Season',
                    value: appState.currentSeason,
                  ),
                  const SizedBox(height: 10),
                  InfoPair(label: 'Status', value: appState.agentStatus),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricCard(
                  title: 'Total Land',
                  value: '${appState.totalLandAcres.toStringAsFixed(0)} Acres',
                  icon: Icons.grid_view_outlined,
                ),
                MetricCard(
                  title: 'Tasks Today',
                  value: '${appState.tasksToday}',
                  icon: Icons.assignment_outlined,
                ),
                MetricCard(
                  title: 'Willing Farmers',
                  value: '${appState.willingCount}',
                  icon: Icons.favorite_outline,
                ),
                MetricCard(
                  title: 'Booked Farmers',
                  value: '${appState.bookedCount}',
                  icon: Icons.check_circle_outline,
                ),
                MetricCard(
                  title: 'Nursery',
                  value: '${appState.nurseryCount}',
                  icon: Icons.spa_outlined,
                ),
                MetricCard(
                  title: 'Transplanted',
                  value: '${appState.transplantedCount}',
                  icon: Icons.grass_outlined,
                ),
                MetricCard(
                  title: 'Harvest',
                  value: '${appState.harvestCount}',
                  icon: Icons.agriculture_outlined,
                ),
                MetricCard(
                  title: 'Procurement',
                  value: '${appState.procurementCount}',
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Today\'s Priorities',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Pending actions across farmers',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 14),
            ...appState.homeTasks.map(
                  (task) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(task: task),
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Farmer Status Tracker',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Latest support and transaction status per farmer',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 14),
            ...trackerFarmers.map(
                  (farmer) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FarmerTrackerCard(farmer: farmer),
                  ),
            ),
            if (trackerFarmers.isNotEmpty)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => context.go('/engage'),
                  child: const Text('View all farmers'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EngagementScreen extends StatefulWidget {
  const EngagementScreen({super.key});

  @override
  State<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends State<EngagementScreen> {
  String _query = '';
  FarmerStatus _filter = FarmerStatus.willing;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.searchFarmers(_query, status: _filter);
    final heading =
    _filter == FarmerStatus.willing ? 'Willing Farmers' : 'Booked Farmers';

    return PageScaffold(
      title: 'Engage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search...',
            onChanged: (value) =>
                setState(() {
                  _query = value;
                }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilterPill(
                  label: 'Willing Farmers',
                  selected: _filter == FarmerStatus.willing,
                  onTap: () =>
                      setState(() {
                        _filter = FarmerStatus.willing;
                      }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilterPill(
                  label: 'Booked Farmers',
                  selected: _filter == FarmerStatus.booked,
                  onTap: () =>
                      setState(() {
                        _filter = FarmerStatus.booked;
                      }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(heading, style: Theme
              .of(context)
              .textTheme
              .titleLarge),
          const SizedBox(height: 14),
          if (farmers.isEmpty)
            const EmptyStateCard(
              message: 'No farmers match the current filter.',
            )
          else
            ...farmers.map(
                  (farmer) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FarmerListCard(
                      farmer: farmer,
                      onTap: () => context.push('/engage/farmer/${farmer.id}'),
                      statusLabel: _filter == FarmerStatus.booked
                          ? farmer.stage.label
                          : farmer.status.label,
                      statusBackground: _filter == FarmerStatus.booked
                          ? stageBackgroundColor(farmer.stage)
                          : null,
                      statusForeground: _filter == FarmerStatus.booked
                          ? stageForegroundColor(farmer.stage)
                          : null,
                      showViewDetails: false,
                      footer: FarmerCardFooter(
                        showSupportChips: _filter == FarmerStatus.booked,
                        cashAcknowledged: farmer.supportHistory.any(
                              (item) => item.type == SupportType.cash,
                        ),
                        kindAcknowledged: farmer.supportHistory.any(
                              (item) => item.type == SupportType.kind,
                        ),
                        onCall: () =>
                            showMockSnackBar(
                              context,
                              'Calling is mocked in v1.',
                            ),
                        onMessage: () =>
                            showMockSnackBar(
                              context,
                              'Messaging is mocked in v1.',
                            ),
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({
    super.key,
    required this.farmerId,
    required this.initialTab,
  });

  final String farmerId;
  final String initialTab;

  bool get isCultivationTab => initialTab == 'cultivation';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmer = appState.farmerById(farmerId);
    final showCultivationTab = farmer.status == FarmerStatus.booked;

    return PageScaffold(
      title: 'Farmer Profile',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        farmer.name,
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ),
                    StatusPill(
                      label: farmer.status.label,
                      background: farmer.status.backgroundColor,
                      foreground: farmer.status.foregroundColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            showMockSnackBar(
                              context,
                              'Calling is mocked in v1.',
                            ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            showMockSnackBar(
                              context,
                              'Messaging is mocked in v1.',
                            ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (showCultivationTab) ...[
            Row(
              children: [
                Expanded(
                  child: FilterPill(
                    label: 'Farmer Profile',
                    selected: !isCultivationTab,
                    onTap: () =>
                        context.go(
                          '/engage/farmer/$farmerId?tab=profile',
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilterPill(
                    label: 'Cultivation',
                    selected: isCultivationTab,
                    onTap: () =>
                        context.go(
                          '/engage/farmer/$farmerId?tab=cultivation',
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (showCultivationTab && isCultivationTab)
            CultivationTab(farmer: farmer)
          else
            ProfileTab(farmer: farmer),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer Details',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 14),
              InfoPair(label: 'Full Name', value: farmer.name),
              const SizedBox(height: 10),
              InfoPair(label: 'Mobile Number', value: farmer.phone),
              const SizedBox(height: 10),
              InfoPair(label: 'Address', value: farmer.location),
              const SizedBox(height: 10),
              InfoPair(
                label: 'Total Land',
                value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
              ),
              const SizedBox(height: 10),
              InfoPair(label: 'Crop', value: farmer.crop),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stage Tracker',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 14),
              StageProgressBar(currentStage: farmer.stage),
              const SizedBox(height: 10),
              Text(
                stageHelperText(farmer.stage),
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Coverage',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Support details are provided by the system based on partnership farming terms.',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium,
              ),
              const SizedBox(height: 14),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Support',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 10),
                      InfoPair(
                        label: 'Cash Advance Eligibility',
                        value: 'Up to ${currency(farmer.cashEligibility)} INR',
                      ),
                      const SizedBox(height: 8),
                      const InfoPair(label: 'Purpose', value: 'Lorem Ipsum'),
                      const SizedBox(height: 8),
                      const InfoPair(
                        label: 'Disbursement Method',
                        value: 'OTP confirmation required',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kind Support',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ...farmer.kindSupportItems.entries.map(
                            (entry) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InfoPair(label: entry.key,
                                  value: entry.value),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (farmer.status == FarmerStatus.booked) ...[
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity Timeline',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 10),
                ...farmer.activities.take(3).map(
                      (activity) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TimelineRow(activity: activity),
                      ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => context.go('/crop-plan'),
                    child: const Text('View Full History'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disbursement History',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 12),
              if (farmer.supportHistory.isEmpty)
                const Text('No data available')
              else
                ...farmer.supportHistory.map(
                      (item) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SupportHistoryTile(transaction: item),
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Procurement History',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 12),
              if (farmer.procurementHistory.isEmpty)
                const Text('No data available')
              else
                ...farmer.procurementHistory.map(
                      (receipt) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProcurementHistoryTile(receipt: receipt),
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('book_farmer_button'),
          style: filledButtonStyle(),
          onPressed: () {
            if (farmer.status == FarmerStatus.willing) {
              context.read<AppState>().bookFarmer(farmer.id);
              showMockSnackBar(
                context,
                '${farmer.name} moved to booked farmers.',
              );
            } else {
              context.push('/support');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              farmer.status == FarmerStatus.willing
                  ? 'Book Farmer'
                  : 'Disburse Support',
            ),
          ),
        ),
      ],
    );
  }
}

class CultivationTab extends StatelessWidget {
  const CultivationTab({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Land Details',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 12),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nursery Land',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InfoPair(
                        label: 'Land Area',
                        value: '${farmer.nurseryLandAcres.toStringAsFixed(
                            0)} acres',
                      ),
                      const SizedBox(height: 8),
                      const InfoPair(
                        label: 'Location',
                        value: 'State, District, Block',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Main Crop Land',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InfoPair(
                        label: 'Land Area',
                        value: '${farmer.mainLandAcres.toStringAsFixed(
                            0)} acres',
                      ),
                      const SizedBox(height: 8),
                      const InfoPair(
                        label: 'Location',
                        value: 'State, District, Block',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Planning',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 12),
              ...farmer.activities.take(3).map(
                    (activity) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ActivityCard(activity: activity),
                    ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => context.go('/crop-plan'),
                  child: const Text('View full crop plan'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pre-Harvest Activity Tracker',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 12),
              ...farmer.activities.take(2).map(
                    (activity) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TimelineRow(activity: activity),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Support',
      description: 'Choose the type of support you want to provide.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionCard(
            icon: Icons.payments_outlined,
            iconBackground: AppColors.brandGreenLight,
            iconColor: AppColors.brandGreenDark,
            title: 'Cash Support',
            description:
            'Disburse cash advances to farmers based on partnership terms and track OTP-based acknowledgments.',
            onTap: () {
              context.read<AppState>().startSupportFlow(SupportType.cash);
              context.push('/support/flow/cash');
            },
          ),
          const SizedBox(height: 14),
          ActionCard(
            icon: Icons.inventory_2_outlined,
            iconBackground: AppColors.brandBlueLight,
            iconColor: AppColors.brandBlue,
            title: 'Kind Support',
            description:
            'Deliver in-kind support items like seeds, fertilizers, and services, then confirm with OTP verification.',
            onTap: () {
              context.read<AppState>().startSupportFlow(SupportType.kind);
              context.push('/support/flow/kind');
            },
          ),
          const SizedBox(height: 24),
          Text('About Support', style: Theme
              .of(context)
              .textTheme
              .titleLarge),
          const SizedBox(height: 10),
          const BulletText(
            'All disbursements require farmer acknowledgment via OTP.',
          ),
          const SizedBox(height: 8),
          const BulletText(
            'Support amounts and items are based on partnership agreements.',
          ),
        ],
      ),
    );
  }
}

class SupportFlowScreen extends StatefulWidget {
  const SupportFlowScreen({super.key, required this.type});

  final SupportType type;

  @override
  State<SupportFlowScreen> createState() => _SupportFlowScreenState();
}

class _SupportFlowScreenState extends State<SupportFlowScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _itemController = TextEditingController();
  String _searchQuery = '';

  static const _kindItemOptions = ['Seeds', 'Fertilizer', 'Pesticides'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final draft = appState.supportDraft;
      if (draft == null || draft.type != widget.type) {
        appState.startSupportFlow(widget.type);
      }
      _syncControllers();
    });
  }

  void _syncControllers() {
    final draft = context
        .read<AppState>()
        .supportDraft;
    if (draft == null) {
      return;
    }
    _amountController.text = draft.cashAmount.toStringAsFixed(0);
    _purposeController.text = draft.purpose;
    _itemController.text = draft.itemName;
  }

  String _descriptionForStep(int stepIndex) {
    if (stepIndex == 0) {
      return 'Select farmer from the list below';
    }
    if (stepIndex == 1) {
      return 'Check farmer information and enter disbursement details';
    }
    return 'Review disbursement summary and confirm transaction';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final draft = appState.supportDraft;
    if (draft == null || draft.type != widget.type) {
      return const SizedBox.shrink();
    }

    final selectedFarmer = draft.farmerId != null
        ? appState.farmerById(draft.farmerId!)
        : null;
    final farmers = appState.searchFarmers(_searchQuery);
    final stepIndex = draft.stepIndex;

    return PageScaffold(
      title: widget.type.label,
      showBack: true,
      description: _descriptionForStep(stepIndex),
      subtitle: 'STEP ${stepIndex + 1} OF 3',
      onBack: () {
        if (stepIndex == 0) {
          appState.cancelSupportFlow();
          context.pop();
          return;
        }
        appState.updateSupportDraft(draft.copyWith(stepIndex: stepIndex - 1));
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('support_primary_button'),
            style: filledButtonStyle(),
            onPressed: () {
              if (stepIndex == 0) {
                if (draft.farmerId == null) {
                  showMockSnackBar(context, 'Select a farmer to continue.');
                  return;
                }
                appState.updateSupportDraft(draft.copyWith(stepIndex: 1));
                _syncControllers();
                return;
              }

              if (stepIndex == 1) {
                final amount =
                    double.tryParse(_amountController.text.trim()) ??
                        draft.cashAmount;
                final updatedDraft = draft.copyWith(
                  cashAmount: amount,
                  purpose: _purposeController.text
                      .trim()
                      .isEmpty
                      ? draft.purpose
                      : _purposeController.text.trim(),
                  itemName: _itemController.text
                      .trim()
                      .isEmpty
                      ? draft.itemName
                      : _itemController.text.trim(),
                  stepIndex: 2,
                );
                appState.updateSupportDraft(updatedDraft);
                return;
              }

              final success = appState.confirmSupportFlow();
              if (success) {
                context.go('/support/success');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                stepIndex == 2
                    ? (widget.type == SupportType.cash
                    ? 'Confirm Transfer'
                    : 'Confirm Disbursement')
                    : stepIndex == 0
                    ? 'Start Disbursement'
                    : 'Continue',
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepIndex == 0) ...[
            SearchField(
              controller: _searchController,
              hintText: 'Search farmer name, location, stage...',
              onChanged: (value) =>
                  setState(() {
                    _searchQuery = value;
                  }),
            ),
            const SizedBox(height: 18),
            Text('All Farmers', style: Theme
                .of(context)
                .textTheme
                .titleLarge),
            const SizedBox(height: 14),
            ...farmers.map(
                  (farmer) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FarmerListCard(
                      farmer: farmer,
                      selected: farmer.id == draft.farmerId,
                      onTap: () =>
                          appState.updateSupportDraft(
                            draft.copyWith(farmerId: farmer.id),
                          ),
                    ),
                  ),
            ),
          ] else
            if (stepIndex == 1 && selectedFarmer != null) ...[
              Text(
                'Farmer Details',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),
              FarmerDetailSummary(farmer: selectedFarmer),
              const SizedBox(height: 18),
              Text(
                'Disbursement Details',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.type == SupportType.cash) ...[
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cash Amount (₹)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DatePickerField(
                        label: 'Date',
                        initialDate: draft.date,
                        onDateSelected: (date) =>
                            appState.updateSupportDraft(
                              draft.copyWith(date: date),
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _purposeController,
                        decoration: const InputDecoration(labelText: 'Purpose'),
                      ),
                    ] else
                      ...[
                        DropdownButtonFormField<String>(
                          value: _kindItemOptions.contains(_itemController.text)
                              ? _itemController.text
                              : _kindItemOptions.first,
                          items: _kindItemOptions
                              .map(
                                (item) =>
                                DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                          )
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'Kind Item'),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _itemController.text = value;
                            });
                          },
                        ),
                      ],
                  ],
                ),
              ),
            ] else
              if (stepIndex == 2 && selectedFarmer != null) ...[
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 14),
                      InfoPair(label: 'Farmer', value: selectedFarmer.name),
                      const SizedBox(height: 10),
                      InfoPair(
                          label: 'Address', value: selectedFarmer.location),
                      const SizedBox(height: 10),
                      if (widget.type == SupportType.cash)
                        InfoPair(
                          label: 'Amount',
                          value: currency(
                            double.tryParse(_amountController.text) ??
                                draft.cashAmount,
                          ),
                        )
                      else
                        InfoPair(
                          label: 'Item',
                          value: _itemController.text
                              .trim()
                              .isEmpty
                              ? draft.itemName
                              : _itemController.text.trim(),
                        ),
                      const SizedBox(height: 10),
                      InfoPair(
                        label: 'Purpose',
                        value: _purposeController.text
                            .trim()
                            .isEmpty
                            ? draft.purpose
                            : _purposeController.text.trim(),
                      ),
                      const SizedBox(height: 10),
                      InfoPair(label: 'Date', value: formatDate(draft.date)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.type == SupportType.cash)
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Transfer Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 14),
                        InfoPair(
                          label: 'Transfer Method',
                          value: 'Bank Transfer',
                        ),
                        SizedBox(height: 10),
                        InfoPair(
                            label: 'Account Holder Name', value: 'Amit Kumar'),
                        SizedBox(height: 10),
                        InfoPair(label: 'Bank Name', value: 'Lorem Ipsum'),
                        SizedBox(height: 10),
                        InfoPair(
                            label: 'Account Number', value: 'xxxxxxxxx879'),
                        SizedBox(height: 10),
                        InfoPair(label: 'Branch Code', value: '-'),
                        SizedBox(height: 10),
                        InfoPair(label: 'Reference No.', value: '11234567890'),
                      ],
                    ),
                  ),
              ],
        ],
      ),
    );
  }
}

class SupportSuccessScreen extends StatelessWidget {
  const SupportSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transaction = context
        .watch<AppState>()
        .lastSupportTransaction;
    final title = transaction?.type == SupportType.kind
        ? 'Kind Support Completed!'
        : 'Cash Disbursement Completed!';

    return PageScaffold(
      title: transaction?.type.label ?? 'Support',
      child: Column(
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.check_circle_outline,
            size: 90,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme
                .of(context)
                .textTheme
                .headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You can view the updated support status later in farmer profile history.',
            textAlign: TextAlign.center,
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge,
          ),
          const SizedBox(height: 30),
          FilledButton(
            style: filledButtonStyle(),
            onPressed: () => context.go('/support'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text('Return To Support'),
            ),
          ),
        ],
      ),
    );
  }
}

class HarvestHubScreen extends StatefulWidget {
  const HarvestHubScreen({super.key});

  @override
  State<HarvestHubScreen> createState() => _HarvestHubScreenState();
}

class _HarvestHubScreenState extends State<HarvestHubScreen> {
  String _query = '';
  String? _selectedFarmerId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.searchFarmers(_query);

    return PageScaffold(
      title: 'Harvesting & Procurement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search farmer name, location...',
            onChanged: (value) =>
                setState(() {
                  _query = value;
                }),
          ),
          const SizedBox(height: 18),
          Text('All Farmers', style: Theme
              .of(context)
              .textTheme
              .titleLarge),
          const SizedBox(height: 14),
          ...farmers.map(
                (farmer) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    highlighted: farmer.id == _selectedFarmerId,
                    child: InkWell(
                      onTap: () =>
                          setState(() {
                            _selectedFarmerId = farmer.id;
                          }),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  farmer.name,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              StatusPill(
                                label: farmer.stage.label,
                                background: stageBackgroundColor(farmer.stage),
                                foreground: stageForegroundColor(farmer.stage),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InfoPair(label: 'Phone', value: farmer.phone),
                          const SizedBox(height: 8),
                          InfoPair(label: 'Location', value: farmer.location),
                          const SizedBox(height: 8),
                          InfoPair(
                            label: 'Land Area',
                            value: '${farmer.totalLandAcres.toStringAsFixed(
                                0)} acres',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              HistoryChip(
                                label: farmer.supportHistory.any(
                                      (item) => item.type == SupportType.kind,
                                )
                                    ? 'Kind: Acknowledged'
                                    : 'Kind: Pending',
                              ),
                              HistoryChip(
                                label: farmer.supportHistory.any(
                                      (item) => item.type == SupportType.cash,
                                )
                                    ? 'Cash: Acknowledged'
                                    : 'Cash: Pending',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('start_procurement_button'),
            style: filledButtonStyle(),
            onPressed: _selectedFarmerId == null
                ? null
                : () {
              appState.startProcurement(_selectedFarmerId!);
              context.push('/harvest/procurement');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Start Procurement'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProcurementFlowScreen extends StatefulWidget {
  const ProcurementFlowScreen({super.key});

  @override
  State<ProcurementFlowScreen> createState() => _ProcurementFlowScreenState();
}

class _ProcurementFlowScreenState extends State<ProcurementFlowScreen> {
  final _harvestQtyController = TextEditingController();
  final _packagingNotesController = TextEditingController();
  final _weighingQtyController = TextEditingController();
  final _weighingNotesController = TextEditingController();
  final _receiptMessageController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _transportNotesController = TextEditingController();
  final _carrierController = TextEditingController();
  String _packagingStatus = 'Completed';

  static const _carrierOptions = ['TRK-5582', 'TRK-4471', 'TRK-6108'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncControllers());
  }

  void _syncControllers() {
    final draft = context
        .read<AppState>()
        .procurementDraft;
    if (draft == null) {
      return;
    }
    _harvestQtyController.text = draft.quantityHarvestedKg.toStringAsFixed(0);
    _packagingNotesController.text = draft.packagingNotes;
    _weighingQtyController.text = draft.finalWeighingQtyKg.toStringAsFixed(0);
    _weighingNotesController.text = draft.weighingNotes;
    _receiptMessageController.text = draft.receiptMessage;
    _driverNameController.text = draft.driverName;
    _driverPhoneController.text = draft.driverPhone;
    _transportNotesController.text = draft.transportNotes;
    _carrierController.text = draft.carrierNumber;
    _packagingStatus = draft.packagingStatus;
  }

  @override
  void dispose() {
    _harvestQtyController.dispose();
    _packagingNotesController.dispose();
    _weighingQtyController.dispose();
    _weighingNotesController.dispose();
    _receiptMessageController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _transportNotesController.dispose();
    _carrierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final draft = appState.procurementDraft;
    if (draft == null) {
      return const PageScaffold(
        title: 'Procurement',
        showBack: true,
        child: EmptyStateCard(
          message: 'Select a farmer from Harvest to start procurement.',
        ),
      );
    }

    final farmer = appState.farmerById(draft.farmerId);
    final step = ProcurementStep.values[draft.stepIndex];
    final readHarvestQty =
        double.tryParse(_harvestQtyController.text) ??
            draft.quantityHarvestedKg;
    final readWeighQty =
        double.tryParse(_weighingQtyController.text) ??
            draft.finalWeighingQtyKg;

    return PageScaffold(
      title: 'Procurement',
      showBack: true,
      onBack: () {
        if (draft.stepIndex == 0) {
          context.pop();
          return;
        }
        appState.updateProcurementDraft(
          draft.copyWith(stepIndex: draft.stepIndex - 1),
        );
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('procurement_primary_button'),
            style: filledButtonStyle(),
            onPressed: () {
              final updatedDraft = _buildUpdatedDraft(draft);
              if (updatedDraft == null) {
                showMockSnackBar(
                  context,
                  'Please complete the current step before continuing.',
                );
                return;
              }
              if (draft.stepIndex == ProcurementStep.values.length - 1) {
                appState.updateProcurementDraft(updatedDraft);
                final success = appState.submitProcurement();
                if (success) {
                  context.go('/harvest/success');
                }
                return;
              }
              appState.updateProcurementDraft(
                updatedDraft.copyWith(stepIndex: draft.stepIndex + 1),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                draft.stepIndex == ProcurementStep.values.length - 1
                    ? 'Submit Procurement'
                    : 'Save and Continue',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              final updatedDraft = _buildUpdatedDraft(draft);
              if (updatedDraft != null) {
                appState.updateProcurementDraft(updatedDraft);
              }
              appState.saveProcurementDraft();
              showMockSnackBar(
                context,
                'Procurement draft saved for this session.',
              );
            },
            child: const Text('Save as Draft'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProcurementStepper(currentStep: draft.stepIndex),
          const SizedBox(height: 18),
          if (step == ProcurementStep.harvesting) ...[
            Text(
              'Farmer Details',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            FarmerDetailSummary(farmer: farmer),
            const SizedBox(height: 18),
            Text(
              'Procurement',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harvesting Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: TextEditingController(text: farmer.crop),
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Crop'),
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    label: 'Harvesting Date',
                    initialDate: draft.harvestingDate,
                    onDateSelected: (date) =>
                        appState.updateProcurementDraft(
                          draft.copyWith(harvestingDate: date),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TimePickerField(
                    label: 'Time of Harvesting',
                    initialTime: draft.harvestingTime,
                    onTimeSelected: (value) =>
                        appState.updateProcurementDraft(
                          draft.copyWith(harvestingTime: value),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _harvestQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity Harvested *',
                      suffixText: 'kg',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (step == ProcurementStep.packaging)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packaging Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Not Started', 'In Progress', 'Completed']
                        .map(
                          (label) =>
                          ChoiceChip(
                            label: Text(label),
                            selected: _packagingStatus == label,
                            onSelected: (_) =>
                                setState(() {
                                  _packagingStatus = label;
                                }),
                          ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    label: 'Packaging Date',
                    initialDate: draft.packagingDate,
                    onDateSelected: (date) =>
                        appState.updateProcurementDraft(
                          draft.copyWith(packagingDate: date),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _packagingNotesController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          if (step == ProcurementStep.weighing) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weighing Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  DatePickerField(
                    label: 'Weighing Date',
                    initialDate: draft.weighingDate,
                    onDateSelected: (date) =>
                        appState.updateProcurementDraft(
                          draft.copyWith(weighingDate: date),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weighingQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Final Weighing Quantity *',
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weighingNotesController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              backgroundColor: AppColors.brandBlueLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity Comparison',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 12),
                  InfoPair(
                    label: 'Harvested Qty',
                    value: '${readHarvestQty.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Final Weighed Qty',
                    value: '${readWeighQty.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Difference',
                    value:
                    '${readWeighQty >= readHarvestQty
                        ? '+'
                        : ''}${(readWeighQty - readHarvestQty).toStringAsFixed(
                        0)} kg',
                  ),
                ],
              ),
            ),
          ],
          if (step == ProcurementStep.price)
            SectionCard(
              backgroundColor: AppColors.brandBlueLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Breakdown',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(
                    label: 'Quantity',
                    value: '${readWeighQty.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Rate per kg',
                    value: '${currency(draft.ratePerKg)} / kg',
                  ),
                  const Divider(height: 24),
                  InfoPair(
                    label: 'Total Amount',
                    value: currency(readWeighQty * draft.ratePerKg),
                  ),
                ],
              ),
            ),
          if (step == ProcurementStep.receipt) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Preview',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(
                      label: 'Date', value: formatDate(draft.transportDate)),
                  const SizedBox(height: 8),
                  const InfoPair(label: 'Receipt No', value: 'REC-10293'),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Farmer', value: farmer.name),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Crop', value: farmer.crop),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Rate per kg',
                    value: currency(draft.ratePerKg),
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Quantity',
                    value: '${readWeighQty.toStringAsFixed(0)} kg',
                  ),
                  const Divider(height: 24),
                  InfoPair(
                    label: 'Total Amount',
                    value: currency(readWeighQty * draft.ratePerKg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () =>
                  showMockSnackBar(
                    context,
                    'Receipt generation is mocked in v1.',
                  ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Generate Receipt'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  showMockSnackBar(
                    context,
                    'Receipt sharing is mocked in v1.',
                  ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share Receipt'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _receiptMessageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
          if (step == ProcurementStep.transport)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transport Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  DatePickerField(
                    label: 'Transport Date',
                    initialDate: draft.transportDate,
                    onDateSelected: (date) =>
                        appState.updateProcurementDraft(
                          draft.copyWith(transportDate: date),
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _carrierOptions.contains(_carrierController.text)
                        ? _carrierController.text
                        : _carrierOptions.first,
                    items: _carrierOptions
                        .map(
                          (carrier) =>
                          DropdownMenuItem<String>(
                            value: carrier,
                            child: Text(carrier),
                          ),
                    )
                        .toList(),
                    decoration:
                    const InputDecoration(labelText: 'Carrier Number'),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _carrierController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _driverNameController,
                    decoration:
                    const InputDecoration(labelText: 'Driver Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _driverPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                    const InputDecoration(labelText: 'Driver Phone No'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _transportNotesController,
                    maxLines: 4,
                    decoration:
                    const InputDecoration(labelText: 'Transport Notes'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  ProcurementDraft? _buildUpdatedDraft(ProcurementDraft draft) {
    final harvestQty =
        double.tryParse(_harvestQtyController.text.trim()) ??
            draft.quantityHarvestedKg;
    final finalQty =
        double.tryParse(_weighingQtyController.text.trim()) ??
            draft.finalWeighingQtyKg;
    final step = ProcurementStep.values[draft.stepIndex];

    switch (step) {
      case ProcurementStep.harvesting:
        if (harvestQty <= 0) {
          return null;
        }
        return draft.copyWith(quantityHarvestedKg: harvestQty);
      case ProcurementStep.packaging:
        return draft.copyWith(
          packagingStatus: _packagingStatus,
          packagingNotes: _packagingNotesController.text
              .trim()
              .isEmpty
              ? draft.packagingNotes
              : _packagingNotesController.text.trim(),
        );
      case ProcurementStep.weighing:
        if (finalQty <= 0) {
          return null;
        }
        return draft.copyWith(
          finalWeighingQtyKg: finalQty,
          weighingNotes: _weighingNotesController.text
              .trim()
              .isEmpty
              ? draft.weighingNotes
              : _weighingNotesController.text.trim(),
        );
      case ProcurementStep.price:
        return draft;
      case ProcurementStep.receipt:
        return draft.copyWith(
          receiptMessage: _receiptMessageController.text
              .trim()
              .isEmpty
              ? draft.receiptMessage
              : _receiptMessageController.text.trim(),
        );
      case ProcurementStep.transport:
        if (_driverNameController.text
            .trim()
            .isEmpty ||
            _driverPhoneController.text
                .trim()
                .isEmpty) {
          return null;
        }
        return draft.copyWith(
          carrierNumber: _carrierController.text
              .trim()
              .isEmpty
              ? draft.carrierNumber
              : _carrierController.text.trim(),
          driverName: _driverNameController.text.trim(),
          driverPhone: _driverPhoneController.text.trim(),
          transportNotes: _transportNotesController.text
              .trim()
              .isEmpty
              ? draft.transportNotes
              : _transportNotesController.text.trim(),
        );
    }
  }
}

class ProcurementSuccessScreen extends StatelessWidget {
  const ProcurementSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final receipt = context
        .watch<AppState>()
        .lastProcurementReceipt;

    return PageScaffold(
      title: 'Procurement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.check_circle_outline,
            size: 88,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 18),
          Text(
            'Procurement Completed',
            style: Theme
                .of(context)
                .textTheme
                .headlineMedium,
          ),
          const SizedBox(height: 6),
          const StatusPill(
            label: 'Submitted',
            background: AppColors.pageBackground,
            foreground: AppColors.textSecondary,
          ),
          const SizedBox(height: 18),
          if (receipt != null)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(label: 'Farmer', value: receipt.farmerName),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Harvesting Date/Time',
                    value: formatDateTime(receipt.harvestDateTime),
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Harvested Qty',
                    value: '${receipt.harvestedQtyKg.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Final Weighed Qty',
                    value: '${receipt.finalQtyKg.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Rate',
                    value: '${currency(receipt.ratePerKg)} / kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                      label: 'Total', value: currency(receipt.totalAmount)),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Receipt', value: receipt.receiptNo),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Transport',
                    value: '${receipt.carrierNumber} • ${receipt.driverName}',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            style: filledButtonStyle(),
            onPressed: () {
              if (receipt == null) {
                context.go('/harvest');
                return;
              }
              context.go('/engage/farmer/${receipt.farmerId}');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text('Open Farmer Profile'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/harvest'),
            child: const Text('Start New Procurement'),
          ),
        ],
      ),
    );
  }
}

class CropPlanScreen extends StatelessWidget {
  const CropPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmer = context
        .watch<AppState>()
        .featuredFarmer;

    return PageScaffold(
      title: 'Farmer Crop Plan',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farmer Details', style: Theme
              .of(context)
              .textTheme
              .titleLarge),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoPair(label: 'Stage', value: farmer.stage.label),
                const SizedBox(height: 10),
                InfoPair(label: 'Full Name', value: farmer.name),
                const SizedBox(height: 10),
                InfoPair(label: 'Mobile Number', value: farmer.phone),
                const SizedBox(height: 10),
                InfoPair(label: 'Address', value: farmer.location),
                const SizedBox(height: 10),
                InfoPair(
                  label: 'Total Land',
                  value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
                ),
                const SizedBox(height: 10),
                InfoPair(label: 'Season', value: farmer.season),
                const SizedBox(height: 10),
                InfoPair(label: 'Crop', value: farmer.crop),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            backgroundColor: AppColors.brandBlueLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9E8FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Stage Mapping',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Nursery  →  Nursery started / plants prepared'),
                const SizedBox(height: 6),
                const Text('Growth  →  Transplanting completed'),
                const SizedBox(height: 6),
                const Text('Harvest  →  Harvest window active'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Planned Activities',
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          ...farmer.activities
              .asMap()
              .entries
              .map(
                (entry) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivityTimelineCard(
                    activity: entry.value,
                    showConnector: entry.key != farmer.activities.length - 1,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class MisaAiPlaceholderScreen extends StatelessWidget {
  const MisaAiPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'MISA AI',
      child: Center(
        child: SectionCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreenLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.brandGreenDark,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'MISA AI is coming soon',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This placeholder keeps the planned navigation structure intact until the final assistant experience is designed.',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () =>
                      showMockSnackBar(
                        context,
                        'Assistant capability is intentionally mocked in v1.',
                      ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View mock state'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.backgroundAssetPath,
  });

  final Widget child;
  final String? backgroundAssetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF41553A),
              Color(0xFF6E874F),
              Color(0xFF8EA250),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (backgroundAssetPath != null)
              Positioned.fill(
                child: Image.asset(
                  backgroundAssetPath!,
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    backgroundAssetPath == null ? 0.12 : 0.18,
                  ),
                ),
              ),
            ),
            if (backgroundAssetPath == null) ...[
              Positioned(
                top: -50,
                left: -40,
                child: _BlurOrb(
                  color: Colors.white.withOpacity(0.08),
                  size: 180,
                ),
              ),
              Positioned(
                bottom: -40,
                right: -20,
                child: _BlurOrb(
                  color: AppColors.brandGreenLight.withOpacity(0.18),
                  size: 220,
                ),
              ),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BrandMarkPainter(),
      ),
    );
  }
}

class BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..color = AppColors.brandBlue;
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandGreen;

    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * 0.8 * math.cos(angle),
        center.dy + radius * 0.8 * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, outer);

    final innerPath = Path()
      ..moveTo(size.width * 0.28, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.50)..lineTo(
          size.width * 0.56, size.height * 0.38)..lineTo(
          size.width * 0.72, size.height * 0.38);
    canvas.drawPath(innerPath, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
    this.description,
    this.subtitle,
    this.footer,
    this.onBack,
  });

  final String title;
  final Widget child;
  final bool showBack;
  final String? description;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: onBack ?? () => context.pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                      Text(
                        title,
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    textAlign: TextAlign.center,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyLarge,
                  ),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.highlighted = false,
    this.useInnerPadding = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final bool highlighted;
  final bool useInnerPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.brandGreen : AppColors.cardBorder,
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D111827),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: useInnerPadding ? const EdgeInsets.all(16) : EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery
          .of(context)
          .size
          .width - 42) / 2,
      child: SectionCard(
        useInnerPadding: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(title, style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.brandGreenDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),
              StatusPill(
                label: task.statusLabel,
                background: task.priority.color.withOpacity(0.12),
                foreground: task.priority.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.subtitle, style: Theme
              .of(context)
              .textTheme
              .bodyMedium),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(task.route),
              child: Text(task.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerTrackerCard extends StatelessWidget {
  const FarmerTrackerCard({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  farmer.name,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),
              StatusPill(
                label: farmer.stage.label,
                background: AppColors.warning.withOpacity(0.12),
                foreground: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HistoryChip(
                label: farmer.supportHistory.any(
                      (item) => item.type == SupportType.cash,
                )
                    ? 'Cash: Acknowledged'
                    : 'Cash: Pending',
              ),
              HistoryChip(
                label: farmer.supportHistory.any(
                      (item) => item.type == SupportType.kind,
                )
                    ? 'Kind: Acknowledged'
                    : 'Kind: Pending',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/engage/farmer/${farmer.id}'),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerListCard extends StatelessWidget {
  const FarmerListCard({
    super.key,
    required this.farmer,
    this.onTap,
    this.selected = false,
    this.statusLabel,
    this.statusBackground,
    this.statusForeground,
    this.footer,
    this.showFooterDivider = false,
    this.showViewDetails = true,
  });

  final FarmerProfile farmer;
  final VoidCallback? onTap;
  final bool selected;
  final String? statusLabel;
  final Color? statusBackground;
  final Color? statusForeground;
  final Widget? footer;
  final bool showFooterDivider;
  final bool showViewDetails;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      highlighted: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    farmer.name,
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                StatusPill(
                  label: statusLabel ?? farmer.status.label,
                  background: statusBackground ?? farmer.status.backgroundColor,
                  foreground: statusForeground ?? farmer.status.foregroundColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoPair(label: 'Phone', value: farmer.phone),
            const SizedBox(height: 8),
            InfoPair(label: 'Location', value: farmer.location),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Land Area',
              value: '${farmer.totalLandAcres.toStringAsFixed(0)} acres',
            ),
            if (footer != null) ...[
              const SizedBox(height: 12),
              if (showFooterDivider) ...[
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
              footer!,
            ] else
              if (onTap != null && showViewDetails) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'View Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      color: AppColors.brandGreenDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class FarmerCardFooter extends StatelessWidget {
  const FarmerCardFooter({
    super.key,
    this.showSupportChips = false,
    this.cashAcknowledged = true,
    this.kindAcknowledged = true,
    this.onCall,
    this.onMessage,
  });

  final bool showSupportChips;
  final bool cashAcknowledged;
  final bool kindAcknowledged;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSupportChips) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HistoryChip(
                label:
                kindAcknowledged ? 'Kind: Acknowledged' : 'Kind: Pending',
              ),
              HistoryChip(
                label:
                cashAcknowledged ? 'Cash: Acknowledged' : 'Cash: Pending',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onCall,
              icon: const Icon(
                Icons.call_outlined,
                color: AppColors.brandGreenDark,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onMessage,
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.brandGreenDark,
                size: 18,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ],
        ),
      ],
    );
  }
}

class InfoPair extends StatelessWidget {
  const InfoPair({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brandGreen.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.brandGreenDark,
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        fillColor: const Color(0xFFF4F5F8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class BulletText extends StatelessWidget {
  const BulletText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• '),
        Expanded(
          child: Text(text, style: Theme
              .of(context)
              .textTheme
              .bodyLarge),
        ),
      ],
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            message,
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class FarmerDetailSummary extends StatelessWidget {
  const FarmerDetailSummary({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final farmerCode = farmer.id.hashCode.abs().toString().padLeft(6, '0');
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  farmer.name,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),
              StatusPill(
                label: farmer.status.label,
                background: farmer.status.backgroundColor,
                foreground: farmer.status.foregroundColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          InfoPair(label: 'Farmer ID', value: farmerCode.substring(0, 6)),
          const SizedBox(height: 8),
          InfoPair(label: 'Phone', value: farmer.phone),
          const SizedBox(height: 8),
          InfoPair(label: 'Address', value: farmer.location),
          const SizedBox(height: 8),
          InfoPair(
            label: 'Land Area',
            value: '${farmer.totalLandAcres.toStringAsFixed(1)} Acre',
          ),
          const SizedBox(height: 8),
          InfoPair(label: 'Crop', value: farmer.crop),
        ],
      ),
    );
  }
}

class StageProgressBar extends StatelessWidget {
  const StageProgressBar({super.key, required this.currentStage});

  final FarmerStage currentStage;

  @override
  Widget build(BuildContext context) {
    final stages = [
      FarmerStage.willing,
      FarmerStage.booked,
      FarmerStage.nursery,
      FarmerStage.growth,
      FarmerStage.harvest,
      FarmerStage.procurement,
      FarmerStage.completed,
    ];
    final currentIndex = stages.indexWhere((stage) => stage == currentStage);

    return Row(
      children: List.generate(stages.length, (index) {
        final isActive = index <= (currentIndex == -1 ? 0 : currentIndex);
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                        isActive ? AppColors.brandGreen : AppColors.cardBorder,
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.brandGreen : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color:
                        isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < (currentIndex == -1 ? 0 : currentIndex)
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stages[index].label,
                textAlign: TextAlign.center,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.activity});

  final CropPlanActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
            activity.completed ? AppColors.brandGreen : AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: Theme
                    .of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(activity.status, style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class SupportHistoryTile extends StatelessWidget {
  const SupportHistoryTile({super.key, required this.transaction});

  final SupportTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amountOrItem = transaction.type == SupportType.cash
        ? currency(transaction.amount ?? 0)
        : (transaction.itemName ?? 'Item');
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.type.label,
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge,
          ),
        ),
        Text(
          amountOrItem,
          style: Theme
              .of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class ProcurementHistoryTile extends StatelessWidget {
  const ProcurementHistoryTile({super.key, required this.receipt});

  final ProcurementReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            receipt.receiptNo,
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge,
          ),
        ),
        Text(
          currency(receipt.totalAmount),
          style: Theme
              .of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});

  final CropPlanActivity activity;

  @override
  Widget build(BuildContext context) {
    final isCompleted = activity.completed;
    final statusColor = isCompleted
        ? AppColors.brandGreen
        : activity.status == 'Planned'
        ? AppColors.textSecondary
        : AppColors.warning;

    return SectionCard(
      useInnerPadding: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.title,
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                StatusPill(
                  label: activity.status,
                  background: statusColor.withOpacity(0.12),
                  foreground: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Planned: ${formatDate(activity.plannedDate)}',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(activity.detail, style: Theme
                .of(context)
                .textTheme
                .bodyLarge),
          ],
        ),
      ),
    );
  }
}

class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({
    super.key,
    required this.activity,
    this.showConnector = true,
  });

  final CropPlanActivity activity;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final isCompleted = activity.completed;
    final color = isCompleted
        ? AppColors.brandGreen
        : activity.status == 'Planned'
        ? AppColors.textSecondary
        : AppColors.warning;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(
                Icons.check,
                size: 14,
                color: AppColors.brandGreen,
              )
                  : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (showConnector)
              Container(width: 2, height: 72, color: AppColors.cardBorder),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: ActivityCard(activity: activity)),
      ],
    );
  }
}

class SupportStepper extends StatelessWidget {
  const SupportStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.brandGreen : Colors.white,
                  border: Border.all(
                    color: isActive
                        ? AppColors.brandGreen
                        : AppColors.cardBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color:
                    isActive ? Colors.white : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: index < currentStep
                        ? AppColors.brandGreen
                        : AppColors.cardBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class ProcurementStepper extends StatelessWidget {
  const ProcurementStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(ProcurementStep.values.length, (index) {
        final step = ProcurementStep.values[index];
        final isDone = index < currentStep;
        final isCurrent = index == currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= currentStep
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isCurrent
                          ? AppColors.brandGreen
                          : Colors.white,
                      border: Border.all(
                        color: isDone || isCurrent
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (index < ProcurementStep.values.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentStep
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class HistoryChip extends StatelessWidget {
  const HistoryChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandGreen.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brandGreenDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
  });

  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2025),
          lastDate: DateTime(2027),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatDate(initialDate)),
      ),
    );
  }
}

class TimePickerField extends StatelessWidget {
  const TimePickerField({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onTimeSelected,
  });

  final String label;
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(initialTime.format(context)),
      ),
    );
  }
}

ButtonStyle filledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.brandGreen,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.brandGreen.withOpacity(0.35),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

void showMockSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String currency(double amount) {
  final formatted = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < formatted.length; i++) {
    final positionFromEnd = formatted.length - i;
    buffer.write(formatted[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '₹$buffer';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month -
      1]} ${date.year}';
}

String formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${formatDate(dateTime)} • $hour:$minute';
}
