import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ekutir_agent_app/main.dart';

Future<void> pumpAuthenticatedApp(
  WidgetTester tester, {
  AppState? appState,
}) async {
  final state = appState ?? AppState.seeded();
  state.isAuthenticated = true;
  await tester.pumpWidget(buildEkAcreGrowthApp(appState: state));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('auth flow reaches home and bottom navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(buildEkAcreGrowthApp(appState: AppState.seeded()));
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

    expect(find.text("Today's Priorities"), findsOneWidget);

    await tester.tap(find.text('Engage'));
    await tester.pumpAndSettle();
    expect(find.text('All Farmers'), findsOneWidget);

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose the type of support you want to provide.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Harvest'));
    await tester.pumpAndSettle();
    expect(find.text('Harvesting & Procurement'), findsOneWidget);
  });

  testWidgets('booking a willing farmer updates app state', (tester) async {
    final appState = AppState.seeded();
    await pumpAuthenticatedApp(tester, appState: appState);

    await tester.tap(find.text('Engage'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Details').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('book_farmer_button')));
    await tester.tap(find.byKey(const Key('book_farmer_button')));
    await tester.pumpAndSettle();

    expect(appState.willingCount, 1);
    expect(appState.bookedCount, 3);
  });

  test('support and procurement flows update history in memory', () {
    final state = AppState.seeded();

    state.startSupportFlow(SupportType.cash);
    state.updateSupportDraft(
      state.supportDraft!.copyWith(
        farmerId: 'anita-devi',
        cashAmount: 50000,
        purpose: 'Input Support',
        stepIndex: 2,
      ),
    );

    expect(state.confirmSupportFlow(), isTrue);
    expect(state.farmerById('anita-devi').supportHistory.length, 1);

    state.startProcurement('amit-kumar');
    state.updateProcurementDraft(
      state.procurementDraft!.copyWith(
        quantityHarvestedKg: 400,
        finalWeighingQtyKg: 420,
        driverName: 'Driver Test',
        stepIndex: ProcurementStep.values.length - 1,
      ),
    );

    expect(state.submitProcurement(), isTrue);
    expect(state.farmerById('amit-kumar').procurementHistory.length, 2);
    expect(state.lastProcurementReceipt?.driverName, 'Driver Test');
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
