import 'dart:typed_data';

import 'package:ekutir_agent_app/main.dart';
import 'package:ekutir_agent_app/models/crop_plan.dart';
import 'package:ekutir_agent_app/models/farmer.dart';
import 'package:ekutir_agent_app/models/misa.dart';
import 'package:ekutir_agent_app/models/procurement.dart';
import 'package:ekutir_agent_app/models/settlement.dart';
import 'package:ekutir_agent_app/models/support.dart';
import 'package:ekutir_agent_app/screens/home_screen.dart';
import 'package:ekutir_agent_app/services/device_action_service.dart';
import 'package:ekutir_agent_app/services/misa_service.dart';
import 'package:ekutir_agent_app/services/plot_location_service.dart';
import 'package:ekutir_agent_app/services/receipt_service.dart';
import 'package:ekutir_agent_app/state/app_state.dart';
import 'package:ekutir_agent_app/state/workflow_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDeviceActionService implements DeviceActionService {
  int callCount = 0;
  int smsCount = 0;
  int shareCount = 0;
  int openMapCount = 0;
  Uri? lastOpenedMapUri;
  PlotLocation? lastOpenedPlotLocation;
  String? lastMapLabel;

  @override
  Future<bool> callPhone(String phoneNumber) async {
    callCount += 1;
    return true;
  }

  @override
  Future<bool> sendSms(String phoneNumber, {String? body}) async {
    smsCount += 1;
    return true;
  }

  @override
  Future<bool> shareText({required String text, String? subject}) async {
    shareCount += 1;
    return true;
  }

  @override
  Future<bool> openMapLocation(PlotLocation plotLocation,
      {String? label}) async {
    openMapCount += 1;
    lastOpenedPlotLocation = plotLocation;
    lastMapLabel = label;
    lastOpenedMapUri = buildMapplsLocationUri(
      plotLocation,
      label: label,
    );
    return true;
  }
}

class FakePlotLocationService implements PlotLocationService {
  FakePlotLocationService({this.nextResult, this.errorMessage});

  PlotLocation? nextResult;
  String? errorMessage;
  int requestCount = 0;
  String? lastLocationHint;

  @override
  Future<PlotLocation?> capturePlotLocation(
    BuildContext context, {
    required String locationHint,
    PlotLocation? currentLocation,
  }) async {
    requestCount += 1;
    lastLocationHint = locationHint;
    if (errorMessage != null) {
      throw PlotLocationException(errorMessage!);
    }
    return nextResult;
  }
}

class FakeReceiptService implements ReceiptService {
  int shareCount = 0;
  int printCount = 0;

  @override
  Future<Uint8List> buildReceiptPdf({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  }) async {
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<bool> printReceipt({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  }) async {
    printCount += 1;
    return true;
  }

  @override
  Future<bool> shareReceipt({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  }) async {
    shareCount += 1;
    return true;
  }
}

class FakeMisaService implements MisaService {
  int requestCount = 0;

  @override
  Future<MisaAiReply> submit(MisaRequest request) async {
    requestCount += 1;
    final prompt = request.prompt.toLowerCase();
    final focusFarmer =
        request.context['focusFarmer'] as Map<String, dynamic>? ?? {};
    final focusFarmerId = focusFarmer['id'] as String?;
    final focusFarmerName = (focusFarmer['name'] as String?) ?? 'Farmer';

    if (prompt.contains('attention')) {
      return MisaAiReply(
        message:
            '$focusFarmerName needs attention first based on pending workflow work.',
        recommendation: MisaRecommendation(
          title: 'Open profile',
          message:
              'Review the farmer profile and continue the most urgent workflow.',
          actionLabel: 'Open profile',
          actionRoute:
              '/engage/farmer/${focusFarmerId ?? 'ravi-kumar'}?tab=profile',
          farmerId: focusFarmerId ?? 'ravi-kumar',
        ),
      );
    }

    if (prompt.contains('support')) {
      return MisaAiReply(
        message: 'There is pending support to close for this farmer.',
        recommendation: MisaRecommendation(
          title: 'Resume support',
          message:
              'Continue the pending support step and close OTP acknowledgement.',
          actionLabel: 'Resume support',
          actionRoute:
              '/support/flow/cash?farmerId=${focusFarmerId ?? 'ravi-kumar'}',
          farmerId: focusFarmerId ?? 'ravi-kumar',
        ),
      );
    }

    return const MisaAiReply(
        message: 'I reviewed the latest workflow context.');
  }
}

AppState buildState({
  WorkflowRepository? repository,
  FakeDeviceActionService? deviceActions,
  MisaService? misaService,
  FakeReceiptService? receiptService,
}) {
  final seedToday = DateTime(2026, 3, 28);
  return AppState.seeded(
    repository: repository,
    today: seedToday,
    deviceActions: deviceActions ?? FakeDeviceActionService(),
    misaService: misaService ?? FakeMisaService(),
    receiptService: receiptService ?? FakeReceiptService(),
  );
}

Future<AppState> buildPersistedState({
  FakeDeviceActionService? deviceActions,
  MisaService? misaService,
  FakeReceiptService? receiptService,
}) async {
  final seedToday = DateTime(2026, 3, 28);
  final repository = await PersistedWorkflowRepository.create(today: seedToday);
  return buildState(
    repository: repository,
    deviceActions: deviceActions,
    misaService: misaService,
    receiptService: receiptService,
  );
}

Future<void> flushPersistedWrites(AppState state) async {
  final repository = state.repository;
  if (repository is PersistedWorkflowRepository) {
    await repository.pendingWrites;
  }
}

Future<void> pumpAuthenticatedApp(
  WidgetTester tester, {
  AppState? appState,
  PlotLocationService? plotLocationService,
}) async {
  final state = appState ?? buildState();
  state.isAuthenticated = true;
  await tester.pumpWidget(
    buildEkAcreGrowthApp(
      appState: state,
      plotLocationService: plotLocationService,
    ),
  );
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('auth flow reaches home and bottom navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(buildEkAcreGrowthApp(appState: buildState()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Sign In To Your Account'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('phone_number_field')),
      '9876543210',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_otp_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp_field')), '1234');
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit_otp_button')));
    await tester.pumpAndSettle();

    expect(find.text('Today\'s Priorities'), findsOneWidget);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    expect(find.text('Willing Farmers'), findsWidgets);

    await tester.tap(find.text('Support').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Choose the type of support you want to provide.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Harvest').last);
    await tester.pumpAndSettle();
    expect(find.text('Harvesting & Procurement'), findsOneWidget);

    await tester.tap(find.text('MISA AI').last);
    await tester.pumpAndSettle();
    expect(find.text('How can I help you today?'), findsOneWidget);
  });

  test('willing farmer becomes booked only after cash support acknowledged',
      () {
    final state = buildState();

    state.startSupportFlow(SupportType.cash, farmerId: 'anita-devi');
    state.updateSupportDraft(
      state.supportDraft!.copyWith(
        stepIndex: 1,
        landDetails: 'Anita main field',
        cropContext: 'Rice / Kharif 2026',
        cashAmount: 50000,
      ),
    );

    expect(state.saveSupportDetails(), isTrue);
    expect(state.farmerById('anita-devi').status, FarmerStatus.willing);

    expect(state.markCashSupportReceived(), isTrue);
    expect(state.farmerById('anita-devi').status, FarmerStatus.willing);

    expect(state.markCashSupportPaid(), isTrue);
    expect(state.farmerById('anita-devi').status, FarmerStatus.willing);

    final code = state.activeSupportRecord!.confirmationCode!;
    state.updateSupportDraft(state.supportDraft!.copyWith(otpInput: code));
    expect(state.confirmSupportOtp(), isTrue);
    expect(state.farmerById('anita-devi').status, FarmerStatus.booked);
    expect(state.farmerById('anita-devi').stage, FarmerStage.booked);
  });

  test('kind support never books a willing farmer', () {
    final state = buildState();

    state.startSupportFlow(SupportType.kind, farmerId: 'parul-begum');
    state.updateSupportDraft(
      state.supportDraft!.copyWith(
        stepIndex: 1,
        landDetails: 'Parul support plot',
        cropContext: 'Rice / Kharif 2026',
        itemName: 'Seeds',
        quantity: 12,
        unit: 'kg',
        kindValue: 9000,
      ),
    );

    expect(state.saveSupportDetails(), isTrue);
    final code = state.activeSupportRecord!.confirmationCode!;
    state.updateSupportDraft(state.supportDraft!.copyWith(otpInput: code));
    expect(state.confirmSupportOtp(), isTrue);
    expect(state.farmerById('parul-begum').status, FarmerStatus.willing);
  });

  test('agent can add a willing farmer with seeded activities and defaults',
      () {
    final state = buildState();

    final farmer = state.addWillingFarmer(
      const NewFarmerDraft(
        name: 'Nina Das',
        phone: '+91 9898989898',
        location: 'Bhaluka',
        crop: 'Rice',
        season: 'Kharif 2026',
        landDetails: 'Nursery beside canal and 8-acre main plot.',
        totalLandAcres: 12,
        nurseryLandAcres: 4,
        mainLandAcres: 8,
      ),
    );

    expect(farmer, isNotNull);
    expect(farmer!.status, FarmerStatus.willing);
    expect(farmer.stage, FarmerStage.willing);
    expect(state.farmerById(farmer.id).phone, '+919898989898');
    expect(state.activitiesFor(farmer.id), isNotEmpty);
    expect(state.supportFor(farmer.id), isEmpty);
    expect(
      state.farmerById(farmer.id).supportPreview,
      equals(defaultSupportPreview()),
    );
  });

  test('agent can add a willing farmer with an optional plot GPS location', () {
    final state = buildState();
    final capturedAt = DateTime(2026, 3, 29, 10, 15);

    final farmer = state.addWillingFarmer(
      NewFarmerDraft(
        name: 'Plot Farmer',
        phone: '+91 9898989800',
        location: 'Karimpur',
        plotLocation: PlotLocation(
          latitude: 22.5726,
          longitude: 88.3639,
          displayAddress: 'Village road plot, Karimpur',
          capturedAt: capturedAt,
        ),
        crop: 'Rice',
        season: 'Kharif 2026',
        landDetails: 'Plot next to irrigation channel.',
        totalLandAcres: 8,
        nurseryLandAcres: 3,
        mainLandAcres: 5,
      ),
    );

    expect(farmer, isNotNull);
    expect(farmer!.plotLocation, isNotNull);
    expect(farmer.plotLocation!.coordinatesLabel, '22.572600, 88.363900');
    expect(
      farmer.plotLocation!.displayAddress,
      'Village road plot, Karimpur',
    );
    expect(state.farmerById(farmer.id).plotLocation!.capturedAt, capturedAt);
  });

  test(
      'add willing farmer rejects duplicate phone numbers and invalid land split',
      () {
    final state = buildState();

    expect(
      state.validateNewFarmerDraft(
        const NewFarmerDraft(
          name: 'Duplicate Farmer',
          phone: '+91 9876543210',
          location: 'Karimpur',
          crop: 'Rice',
          season: 'Kharif 2026',
          landDetails: 'Duplicate land details.',
          totalLandAcres: 10,
          nurseryLandAcres: 4,
          mainLandAcres: 6,
        ),
      ),
      'A farmer with this phone number already exists.',
    );

    expect(
      state.validateNewFarmerDraft(
        const NewFarmerDraft(
          name: 'Mismatch Farmer',
          phone: '+91 9000000001',
          location: 'Karimpur',
          crop: 'Rice',
          season: 'Kharif 2026',
          landDetails: 'Mismatch land details.',
          totalLandAcres: 10,
          nurseryLandAcres: 3,
          mainLandAcres: 6,
        ),
      ),
      'Nursery and main land must add up to total land.',
    );

    expect(
      state.addWillingFarmer(
        const NewFarmerDraft(
          name: 'Blocked Farmer',
          phone: '+91 9000000002',
          location: 'Karimpur',
          crop: 'Rice',
          season: 'Kharif 2026',
          landDetails: 'Blocked land details.',
          totalLandAcres: 10,
          nurseryLandAcres: 2,
          mainLandAcres: 6,
        ),
      ),
      isNull,
    );
  });

  test('workflow snapshot preserves plot GPS and old data still loads', () {
    final capturedAt = DateTime(2026, 3, 29, 9, 45);
    final snapshot = WorkflowSnapshot(
      farmers: [
        FarmerProfile(
          id: 'plot-farmer',
          name: 'Plot Farmer',
          phone: '+919000000010',
          location: 'Karimpur',
          plotLocation: PlotLocation(
            latitude: 22.5726,
            longitude: 88.3639,
            displayAddress: 'Village road plot, Karimpur',
            capturedAt: capturedAt,
          ),
          totalLandAcres: 8,
          crop: 'Rice',
          season: 'Kharif 2026',
          status: FarmerStatus.willing,
          stage: FarmerStage.willing,
          nurseryLandAcres: 3,
          mainLandAcres: 5,
          landDetails: 'Plot next to irrigation channel.',
          supportPreview: defaultSupportPreview(),
        ),
      ],
      activities: const {},
      support: const {},
      procurement: const {},
      settlements: const {},
    );

    final roundTrip = WorkflowSnapshot.fromJson(snapshot.toJson());
    expect(roundTrip.farmers.single.plotLocation, isNotNull);
    expect(
      roundTrip.farmers.single.plotLocation!.displayAddress,
      'Village road plot, Karimpur',
    );
    expect(
      roundTrip.farmers.single.plotLocation!.capturedAt,
      capturedAt,
    );

    final legacyJson = snapshot.toJson();
    final farmerJson =
        (legacyJson['farmers'] as List<dynamic>).single as Map<String, dynamic>;
    farmerJson.remove('plotLocation');

    final legacyRoundTrip = WorkflowSnapshot.fromJson(legacyJson);
    expect(legacyRoundTrip.farmers.single.plotLocation, isNull);
  });

  test('openFarmerPlotLocation builds the Mappls external URL', () async {
    final deviceActions = FakeDeviceActionService();
    final state = buildState(deviceActions: deviceActions);

    final farmer = state.addWillingFarmer(
      NewFarmerDraft(
        name: 'Map Farmer',
        phone: '+91 9898989700',
        location: 'Karimpur',
        plotLocation: PlotLocation(
          latitude: 22.5726,
          longitude: 88.3639,
          displayAddress: 'Village road plot, Karimpur',
          capturedAt: DateTime(2026, 3, 29, 8, 0),
        ),
        crop: 'Rice',
        season: 'Kharif 2026',
        landDetails: 'Plot next to irrigation channel.',
        totalLandAcres: 8,
        nurseryLandAcres: 3,
        mainLandAcres: 5,
      ),
    );

    final opened = await state.openFarmerPlotLocation(farmer!.id);

    expect(opened, isTrue);
    expect(deviceActions.openMapCount, 1);
    expect(
      deviceActions.lastOpenedMapUri.toString(),
      'https://mappls.com/location/22.5726,88.3639?title=Map+Farmer',
    );
  });

  test('crop activity updates promote farmer stage', () {
    final state = buildState();

    expect(state.farmerById('ravi-kumar').stage, FarmerStage.booked);

    expect(
      state.updateCropActivityStatus(
        'ravi-kumar',
        'ravi-kumar_n1',
        CropActivityStatus.inProgress,
      ),
      isTrue,
    );
    expect(state.farmerById('ravi-kumar').stage, FarmerStage.nursery);

    expect(
      state.updateCropActivityStatus(
        'ravi-kumar',
        'ravi-kumar_t1',
        CropActivityStatus.completed,
      ),
      isTrue,
    );
    expect(state.farmerById('ravi-kumar').stage, FarmerStage.growth);

    expect(
      state.updateCropActivityStatus(
        'ravi-kumar',
        'ravi-kumar_h1',
        CropActivityStatus.inProgress,
      ),
      isTrue,
    );
    expect(state.farmerById('ravi-kumar').stage, FarmerStage.harvest);
  });

  test(
      'harvest dates come only from crop plan and procurement does not settle automatically',
      () {
    final state = buildState();
    final harvestDates = state.harvestDateOptionsFor('amit-kumar');

    expect(harvestDates, isNotEmpty);

    state.startProcurementFlow('amit-kumar');
    final record = state.activeProcurementRecord!;
    expect(record.harvestDateOptions, equals(harvestDates));

    state.updateProcurementDraft(
      record.copyWith(
        transportDate: state.today,
        carrierNumber: 'TRK-9911',
        driverName: 'Driver Test',
        driverPhone: '+91 9876509999',
        transportNotes: 'Loaded from collection center.',
        transportAssigned: true,
      ),
    );
    expect(state.submitProcurement(), isTrue);
    expect(state.farmerById('amit-kumar').stage, FarmerStage.procurement);
    expect(
      state.settlementPreviewFor('amit-kumar').status,
      SettlementStatus.pendingReconciliation,
    );
  });

  test(
      'home priorities are farmer-specific and deep-link to exact next actions',
      () {
    final state = buildState();
    final tasks = state.homeTasks;

    expect(
      tasks.any(
        (task) => task.route == '/support/flow/cash?farmerId=anita-devi',
      ),
      isTrue,
    );
    expect(
      tasks.any(
        (task) => task.route == '/support/flow/cash?farmerId=parul-begum',
      ),
      isTrue,
    );
    expect(
      tasks.any((task) => task.route.contains('recordId=cash_amit_1')),
      isTrue,
    );
    expect(
      tasks.any((task) => task.route == '/engage?tab=willing'),
      isFalse,
    );
  });

  test('settlement requires acknowledged support plus procurement', () {
    final state = buildState();

    expect(state.canCompleteSettlement('ravi-kumar'), isFalse);
    expect(state.completeSettlement('ravi-kumar'), isFalse);

    state.startProcurementFlow('amit-kumar');
    final record = state.activeProcurementRecord!;
    state.updateProcurementDraft(
      record.copyWith(
        transportDate: state.today,
        carrierNumber: 'TRK-1100',
        driverName: 'Harish',
        driverPhone: '+91 9876510101',
        transportNotes: 'Ready for dispatch.',
        transportAssigned: true,
      ),
    );
    expect(state.submitProcurement(), isTrue);
    expect(state.canCompleteSettlement('amit-kumar'), isFalse);

    state.startSupportFlow(
      SupportType.cash,
      farmerId: 'amit-kumar',
      recordId: 'cash_amit_1',
    );
    final code = state.activeSupportRecord!.confirmationCode!;
    state.updateSupportDraft(state.supportDraft!.copyWith(otpInput: code));
    expect(state.confirmSupportOtp(), isTrue);

    expect(state.canCompleteSettlement('amit-kumar'), isTrue);
    expect(state.completeSettlement('amit-kumar'), isTrue);
    expect(
      state.farmerById('amit-kumar').stage,
      FarmerStage.settlementCompleted,
    );
    expect(state.finalizedSupportFor('amit-kumar'), isNotEmpty);
  });

  test('settlement stays blocked while any support record remains unresolved',
      () {
    final state = buildState();

    state.startProcurementFlow('ravi-kumar');
    final record = state.activeProcurementRecord!;
    state.updateProcurementDraft(
      record.copyWith(
        selectedHarvestDate: state.harvestDateOptionsFor('ravi-kumar').first,
        quantityHarvestedKg: 320,
        packagingDone: true,
        packagingDate: state.today,
        packagingNotes: 'Packed and tagged.',
        weighingDone: true,
        weighingDate: state.today,
        finalWeighingQtyKg: 312,
        weighingNotes: 'Weighed at the local hub.',
        ratePerKg: 41,
        receiptGenerated: true,
        receiptNumber: 'REC-2201',
        receiptMessage: 'Ready for settlement.',
        transportAssigned: true,
        transportDate: state.today,
        carrierNumber: 'TRK-2201',
        driverName: 'Rakesh',
        driverPhone: '+91 9876510102',
        transportNotes: 'Loaded for dispatch.',
      ),
    );
    expect(state.submitProcurement(), isTrue);
    expect(state.canCompleteSettlement('ravi-kumar'), isTrue);

    state.startSupportFlow(SupportType.kind, farmerId: 'ravi-kumar');
    state.updateSupportDraft(
      state.supportDraft!.copyWith(
        stepIndex: 1,
        landDetails: 'Primary plot beside collection point.',
        cropContext: 'Rice / Kharif 2026',
        itemName: 'Fertilizer',
        quantity: 4,
        unit: 'bags',
        kindValue: 6000,
      ),
    );
    expect(state.saveSupportDetails(), isTrue);
    expect(state.canCompleteSettlement('ravi-kumar'), isFalse);

    final code = state.activeSupportRecord!.confirmationCode!;
    state.updateSupportDraft(state.supportDraft!.copyWith(otpInput: code));
    expect(state.confirmSupportOtp(), isTrue);
    expect(state.canCompleteSettlement('ravi-kumar'), isTrue);
  });

  testWidgets(
      'engage willing farmer routes to cash support instead of direct booking',
      (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anita Devi').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_cash_advance_button')), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const Key('start_cash_advance_button')));
    await tester.tap(find.byKey(const Key('start_cash_advance_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cash Support'), findsWidgets);
    expect(appState.farmerById('anita-devi').status, FarmerStatus.willing);
  });

  testWidgets('cash support flow enforces OTP and books farmer on acknowledge',
      (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Support').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash Support').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Anita Devi').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('support_primary_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('support_primary_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('support_primary_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('support_primary_button')));
    await tester.pumpAndSettle();

    final code = appState.activeSupportRecord!.confirmationCode!;
    await tester.enterText(find.byType(EditableText).last, code);
    await tester.pump();
    await tester.tap(find.byKey(const Key('support_primary_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cash Disbursement Completed'), findsOneWidget);
    expect(appState.farmerById('anita-devi').status, FarmerStatus.booked);
  });

  testWidgets(
      'support screen shows post-disbursement summary and OTP follow-up', (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Support').last);
    await tester.pumpAndSettle();

    expect(find.text('Post-Disbursement Summary'), findsOneWidget);
    expect(find.text('OTP Follow-up'), findsOneWidget);
    expect(find.textContaining('Total Cash Disbursed'), findsWidgets);
  });

  testWidgets('farmer profile separates pending support from finalized history',
      (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Farmers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Amit Kumar').first);
    await tester.tap(find.text('Amit Kumar').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Pending Support Records'), findsOneWidget);
    expect(find.text('Disbursement History'), findsOneWidget);
    expect(
      find.text('History will appear here after reconciliation is completed.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Suresh Patel').first);
    await tester.tap(find.text('Suresh Patel').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Pending Support Records'), findsOneWidget);
    expect(find.text('No pending support records.'), findsOneWidget);
    expect(find.text('Disbursement History'), findsOneWidget);
    expect(find.text('Finalized'), findsWidgets);
  });

  testWidgets(
      'MISA general and farmer-specific flows produce actionable recommendations',
      (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('MISA AI').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Who needs attention today?'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Open profile'), findsOneWidget);

    await tester.tap(find.text('Farmer-specific'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ravi Kumar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('What support is pending for this farmer?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resume support'), findsWidgets);
  });

  testWidgets('device actions use the injected services', (tester) async {
    final fakeDevice = FakeDeviceActionService();
    final fakeReceipt = FakeReceiptService();
    final appState = buildState(
      deviceActions: fakeDevice,
      receiptService: fakeReceipt,
    );
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Farmers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ravi Kumar').first);
    await tester.tap(find.text('Ravi Kumar').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Call'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Call'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(fakeDevice.callCount, 1);
    expect(fakeDevice.smsCount, 1);
    expect(fakeDevice.shareCount, 1);
    expect(fakeReceipt.shareCount, 0);
    expect(fakeReceipt.printCount, 0);
  });

  test('receipt actions use the injected receipt service', () async {
    final fakeReceipt = FakeReceiptService();
    final state = buildState(receiptService: fakeReceipt);

    final shared = await state.shareProcurementReceipt('proc_suresh_1');
    final printed = await state.printProcurementReceipt('proc_suresh_1');

    expect(shared, isTrue);
    expect(printed, isTrue);
    expect(fakeReceipt.shareCount, 1);
    expect(fakeReceipt.printCount, 1);
  });

  test('persisted repository restores full workflow snapshot', () async {
    SharedPreferences.setMockInitialValues({});

    final state = await buildPersistedState();
    final farmer = state.addWillingFarmer(
      const NewFarmerDraft(
        name: 'Rina Paul',
        phone: '+91 9000000100',
        location: 'Trishal',
        crop: 'Tomato',
        season: 'Summer 2026',
        landDetails: '3-acre nursery and 7-acre main field.',
        totalLandAcres: 10,
        nurseryLandAcres: 3,
        mainLandAcres: 7,
      ),
    );
    expect(farmer, isNotNull);

    expect(
      state.updateCropActivityStatus(
        farmer!.id,
        '${farmer.id}_n1',
        CropActivityStatus.inProgress,
      ),
      isTrue,
    );
    await flushPersistedWrites(state);

    final reloadedState = await buildPersistedState();

    expect(reloadedState.farmerById(farmer.id).name, 'Rina Paul');
    expect(
      reloadedState.activitiesFor(farmer.id).first.status,
      CropActivityStatus.inProgress,
    );
    expect(reloadedState.supportFor('ravi-kumar'), isNotEmpty);
    expect(reloadedState.procurementFor('suresh-patel'), isNotEmpty);
    expect(
      reloadedState.settlementPreviewFor('suresh-patel').status,
      SettlementStatus.completed,
    );
  });

  testWidgets('engage add willing farmer persists after app rebuild', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final appState = await buildPersistedState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_willing_farmer_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('new_farmer_name_field')),
      'Nandita Roy',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_phone_field')),
      '+91 9000000200',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_location_field')),
      'Karimpur',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_crop_field')),
      'Rice',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_season_field')),
      'Kharif 2026',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_land_details_field')),
      '2-acre nursery and 8-acre main plot.',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_total_land_field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_nursery_land_field')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_main_land_field')),
      '8',
    );
    await tester.tap(find.byKey(const Key('save_new_farmer_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nandita Roy'), findsWidgets);
    await flushPersistedWrites(appState);

    final reloadedState = await buildPersistedState();
    await pumpAuthenticatedApp(tester, appState: reloadedState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Farmers'));
    await tester.pumpAndSettle();

    expect(find.text('Nandita Roy'), findsWidgets);
  });

  testWidgets('add willing farmer shows captured plot GPS preview', (
    tester,
  ) async {
    final plotLocationService = FakePlotLocationService(
      nextResult: PlotLocation(
        latitude: 22.5726,
        longitude: 88.3639,
        displayAddress: 'Village road plot, Karimpur',
        capturedAt: DateTime(2026, 3, 29, 11, 0),
      ),
    );

    await pumpAuthenticatedApp(
      tester,
      plotLocationService: plotLocationService,
    );

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_willing_farmer_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('new_farmer_location_field')),
      'Karimpur',
    );
    await tester
        .ensureVisible(find.byKey(const Key('capture_plot_location_button')));
    await tester.tap(find.byKey(const Key('capture_plot_location_button')));
    await tester.pumpAndSettle();

    expect(plotLocationService.requestCount, 1);
    expect(plotLocationService.lastLocationHint, 'Karimpur');
    expect(find.text('Village road plot, Karimpur'), findsOneWidget);
    expect(find.text('22.572600, 88.363900'), findsOneWidget);
    expect(find.text('Retake Plot Location'), findsOneWidget);
  });

  testWidgets('farmer details show plot GPS and open in map action', (
    tester,
  ) async {
    final fakeDevice = FakeDeviceActionService();
    final appState = buildState(deviceActions: fakeDevice);
    appState.addWillingFarmer(
      NewFarmerDraft(
        name: 'Plot Details Farmer',
        phone: '+91 9000000999',
        location: 'Karimpur',
        plotLocation: PlotLocation(
          latitude: 22.5726,
          longitude: 88.3639,
          displayAddress: 'Village road plot, Karimpur',
          capturedAt: DateTime(2026, 3, 29, 8, 15),
        ),
        crop: 'Rice',
        season: 'Kharif 2026',
        landDetails: 'Plot next to irrigation channel.',
        totalLandAcres: 8,
        nurseryLandAcres: 3,
        mainLandAcres: 5,
      ),
    );

    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Plot Details Farmer').first);
    await tester.tap(find.text('Plot Details Farmer').first);
    await tester.pumpAndSettle();

    expect(find.text('Plot Location'), findsWidgets);
    expect(find.text('Village road plot, Karimpur'), findsOneWidget);
    expect(find.text('Coordinates: 22.572600, 88.363900'), findsOneWidget);

    await tester
        .ensureVisible(find.widgetWithText(OutlinedButton, 'Open in Map'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Open in Map'));
    await tester.pumpAndSettle();

    expect(fakeDevice.openMapCount, 1);
  });

  testWidgets('plot GPS persists after app rebuild and shows in details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final plotLocationService = FakePlotLocationService(
      nextResult: PlotLocation(
        latitude: 22.5726,
        longitude: 88.3639,
        displayAddress: 'Village road plot, Karimpur',
        capturedAt: DateTime(2026, 3, 29, 12, 0),
      ),
    );
    final appState = await buildPersistedState();
    await pumpAuthenticatedApp(
      tester,
      appState: appState,
      plotLocationService: plotLocationService,
    );

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_willing_farmer_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('new_farmer_name_field')),
      'Plot Persist Farmer',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_phone_field')),
      '+91 9000000210',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_location_field')),
      'Karimpur',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_crop_field')),
      'Rice',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_season_field')),
      'Kharif 2026',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_land_details_field')),
      '2-acre nursery and 8-acre main plot.',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_total_land_field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_nursery_land_field')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('new_farmer_main_land_field')),
      '8',
    );
    await tester
        .ensureVisible(find.byKey(const Key('capture_plot_location_button')));
    await tester.tap(find.byKey(const Key('capture_plot_location_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save_new_farmer_button')));
    await tester.tap(find.byKey(const Key('save_new_farmer_button')));
    await tester.pumpAndSettle();

    await flushPersistedWrites(appState);

    final reloadedState = await buildPersistedState();
    await pumpAuthenticatedApp(tester, appState: reloadedState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Farmers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Plot Persist Farmer').first);
    await tester.tap(find.text('Plot Persist Farmer').first);
    await tester.pumpAndSettle();

    expect(find.text('Village road plot, Karimpur'), findsOneWidget);
    expect(find.text('Coordinates: 22.572600, 88.363900'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Open in Map'), findsOneWidget);
  });

  testWidgets(
    'golden placeholder for home screen',
    (tester) async {
      await pumpAuthenticatedApp(tester);
      expect(find.text("Today's Priorities"), findsOneWidget);
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen.png'),
      );
    },
    skip: true,
  );
}
