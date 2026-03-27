import 'dart:typed_data';

import 'package:ekutir_agent_app/main.dart';
import 'package:ekutir_agent_app/models/crop_plan.dart';
import 'package:ekutir_agent_app/models/farmer.dart';
import 'package:ekutir_agent_app/models/procurement.dart';
import 'package:ekutir_agent_app/models/settlement.dart';
import 'package:ekutir_agent_app/models/support.dart';
import 'package:ekutir_agent_app/screens/home_screen.dart';
import 'package:ekutir_agent_app/services/device_action_service.dart';
import 'package:ekutir_agent_app/services/receipt_service.dart';
import 'package:ekutir_agent_app/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceActionService implements DeviceActionService {
  int callCount = 0;
  int smsCount = 0;
  int shareCount = 0;

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

AppState buildState({
  FakeDeviceActionService? deviceActions,
  FakeReceiptService? receiptService,
}) {
  final seedToday = DateTime(2026, 3, 28);
  return AppState.seeded(
    today: seedToday,
    deviceActions: deviceActions ?? FakeDeviceActionService(),
    receiptService: receiptService ?? FakeReceiptService(),
  );
}

Future<void> pumpAuthenticatedApp(
  WidgetTester tester, {
  AppState? appState,
}) async {
  final state = appState ?? buildState();
  state.isAuthenticated = true;
  await tester.pumpWidget(buildEkAcreGrowthApp(appState: state));
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

  test('willing farmer becomes booked only after cash support acknowledged', () {
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

  test('harvest dates come only from crop plan and procurement does not settle automatically', () {
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

  test('home priorities are farmer-specific and deep-link to exact next actions', () {
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

  test('settlement stays blocked while any support record remains unresolved', () {
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

  testWidgets('engage willing farmer routes to cash support instead of direct booking', (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anita Devi').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_cash_advance_button')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('start_cash_advance_button')));
    await tester.tap(find.byKey(const Key('start_cash_advance_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cash Support'), findsWidgets);
    expect(appState.farmerById('anita-devi').status, FarmerStatus.willing);
  });

  testWidgets('cash support flow enforces OTP and books farmer on acknowledge', (
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

  testWidgets('support screen shows post-disbursement summary and OTP follow-up', (
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

  testWidgets('farmer profile separates pending support from finalized history', (
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

  testWidgets('MISA general and farmer-specific flows produce actionable recommendations', (
    tester,
  ) async {
    final appState = buildState();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('MISA AI').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Who needs attention today?'));
    await tester.pumpAndSettle();
    expect(find.text('Open profile'), findsOneWidget);

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
