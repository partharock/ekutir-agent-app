import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'theme/app_colors.dart';
import 'models/procurement.dart';
import 'models/support.dart';
import 'state/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/engagement_screens.dart';
import 'screens/support_screens.dart';
import 'screens/harvest_screens.dart';
import 'screens/crop_plan_screen.dart';
import 'screens/misa_ai_screen.dart';
import 'services/misa_service.dart';
import 'services/plot_location_service.dart';

const bool _debugAutoLogin = bool.fromEnvironment('AUTO_LOGIN');
const String _debugInitialRoute =
    String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/');
const String _debugSupportFlow =
    String.fromEnvironment('DEBUG_SUPPORT_FLOW', defaultValue: '');
const int _debugSupportStep =
    int.fromEnvironment('DEBUG_SUPPORT_STEP', defaultValue: -1);
const int _debugProcurementStep =
    int.fromEnvironment('DEBUG_PROCUREMENT_STEP', defaultValue: -1);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await AppState.create();
  if (_debugAutoLogin) {
    appState.isAuthenticated = true;
  }
  _applyDebugSeed(appState);
  runApp(buildEkAcreGrowthApp(appState: appState));
}

void _applyDebugSeed(AppState appState) {
  if (_debugSupportFlow.isNotEmpty) {
    final type =
        _debugSupportFlow == 'kind' ? SupportType.kind : SupportType.cash;
    appState.startSupportFlow(type, farmerId: appState.topPriorityFarmer.id);
    if (appState.supportDraft != null) {
      appState.updateSupportDraft(
        appState.supportDraft!.copyWith(
          stepIndex: _debugSupportStep < 0 ? 0 : _debugSupportStep,
        ),
      );
    }
  }

  if (_debugProcurementStep >= 0) {
    appState.startProcurementFlow(
      appState.topPriorityFarmer.id,
      step: ProcurementStep.values[_debugProcurementStep],
    );
  }
}

Widget buildEkAcreGrowthApp({
  AppState? appState,
  MisaService? misaService,
  PlotLocationService? plotLocationService,
}) {
  final state = appState ?? AppState.seeded(misaService: misaService);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: state),
      Provider<PlotLocationService>.value(
        value: plotLocationService ?? const MapplsPlotLocationService(),
      ),
    ],
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
      title: 'eK Acre Growth'.tr,
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
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final tab = switch (tabParam) {
                'booked' => FarmerDirectoryTab.booked,
                'all' => FarmerDirectoryTab.all,
                _ => FarmerDirectoryTab.willing,
              };
              return EngagementScreen(initialTab: tab);
            },
          ),
          GoRoute(
            path: '/engage/add',
            builder: (context, state) => const AddWillingFarmerScreen(),
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
              return SupportFlowScreen(
                type: type,
                farmerId: state.uri.queryParameters['farmerId'],
                recordId: state.uri.queryParameters['recordId'],
              );
            },
          ),
          GoRoute(
            path: '/support/success',
            builder: (context, state) => SupportSuccessScreen(
              farmerId: state.uri.queryParameters['farmerId'],
            ),
          ),
          GoRoute(
            path: '/harvest',
            builder: (context, state) => const HarvestHubScreen(),
          ),
          GoRoute(
            path: '/harvest/procurement',
            builder: (context, state) => ProcurementFlowScreen(
              farmerId: state.uri.queryParameters['farmerId'],
              recordId: state.uri.queryParameters['recordId'],
              initialStep: state.uri.queryParameters['step'],
            ),
          ),
          GoRoute(
            path: '/harvest/success',
            builder: (context, state) => ProcurementSuccessScreen(
              recordId: state.uri.queryParameters['recordId'],
            ),
          ),
          GoRoute(
            path: '/crop-plan',
            builder: (context, state) => CropPlanScreen(
              farmerId: state.uri.queryParameters['farmerId'],
            ),
          ),
          GoRoute(
            path: '/misa-ai',
            builder: (context, state) => MisaAiScreen(
              initialMode: state.uri.queryParameters['mode'],
              farmerId: state.uri.queryParameters['farmerId'],
            ),
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
        fontWeight: FontWeight.w800,
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.heroMist,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return base.textTheme.bodySmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.heroForest : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.heroForest : AppColors.textSecondary,
        );
      }),
    ),
  );
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
    context.watch<AppState>();
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
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: 'Engage'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.monetization_on_outlined),
            selectedIcon: Icon(Icons.monetization_on),
            label: 'Support'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: 'Harvest'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Crop Plan'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'MISA AI'.tr,
          ),
        ],
      ),
    );
  }
}
