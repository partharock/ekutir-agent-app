import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/agent_profile_drawer.dart';
import '../widgets/common.dart';
import '../widgets/device_chrome.dart';
import 'engagement_screens.dart' show FarmerTrackerCard;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.homeTasks.take(3).toList();
    final trackerFarmers = appState.priorityFarmers.take(2).toList();

    // Target progress values
    final farmerAchieved = appState.farmers.length;
    final farmerTarget = appState.targetFarmers;
    final farmerProgress = (farmerAchieved / farmerTarget).clamp(0.0, 1.0);
    final landAchieved = appState.totalLandAcres;
    final landTarget = appState.targetLandAcres;
    final landProgress = (landAchieved / landTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AgentProfileDrawer(),
      floatingActionButton: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF294190), Color(0xFF4F8506)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          tooltip: 'Open assistant'.tr,
          onPressed: () => context.go('/misa-ai'),
          icon: const Icon(
            Icons.support_agent,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space for SimulatedStatusBar (52px)
                    const SizedBox(height: 52),
                    // Header — full width (no horizontal padding here)
                    _HomeHeader(agentName: appState.agentName),
                    const SizedBox(height: 20),

                    // ── Target Tracker ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Tracker'.tr,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1B1F),
                                ),
                          ),
                          const SizedBox(height: 12),
                          _HomeTargetCard(
                            icon: Icons.person_outline,
                            label: 'Farmer Target'.tr,
                            achieved: farmerAchieved,
                            target: farmerTarget,
                            progress: farmerProgress,
                            unit: '',
                          ),
                          const SizedBox(height: 10),
                          _HomeTargetCard(
                            icon: Icons.map_outlined,
                            label: 'Land Target'.tr,
                            achieved: landAchieved.toInt(),
                            target: landTarget.toInt(),
                            progress: landProgress,
                            unit: 'ac',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ── Farmer-wise Tracking ─────────────────────────
                    if (trackerFarmers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Farmer-wise Tracking'.tr,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1C1B1F),
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Latest stage and transactions status per farmer'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: const Color(0xFF757575),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...trackerFarmers.map(
                        (farmer) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: FarmerTrackerCard(farmer: farmer),
                        ),
                      ),
                      // View all farmers button
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => context.go('/engage'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF294190),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: Text(
                            'View all farmers'.tr,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF294190),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── MISA AI Card ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MisaAiCard(),
                    ),
                    const SizedBox(height: 30),

                    // ── Today's Priorities ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Today's Priorities".tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1B1F),
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: EmptyStateCard(
                          message:
                              'No urgent workflow items are pending today.'.tr,
                        ),
                      )
                    else
                      ...tasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                          child: TaskCard(task: task),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SimulatedStatusBar(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Target Tracker Card ─────────────────────────────────────────────────

class _HomeTargetCard extends StatelessWidget {
  const _HomeTargetCard({
    required this.icon,
    required this.label,
    required this.achieved,
    required this.target,
    required this.progress,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final int achieved;
  final int target;
  final double progress;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final u = unit.isNotEmpty ? ' $unit' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADCE0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF1C1B1F)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
              ),
              Text(
                '$achieved$u / $target$u',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF1C1B1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar — #EAEAEA bg, #4F8506 fill, radius 33, height 12
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(33),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F8506),
                    borderRadius: BorderRadius.circular(33),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── MISA AI Collapsed Card ───────────────────────────────────────────────────

class _MisaAiCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/misa-ai'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          border: Border.all(color: const Color(0xFFDADCE0), width: 1.35),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14.1,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFDFE5F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Color(0xFF294190),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISA AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ask for the next action, pending OTPs, or settlement readiness.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: const Color(0xFF1C1B1F),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => context.go('/misa-ai'),
                    child: Text(
                      'Open assistant'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF294190),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.agentName});

  final String agentName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDADCE0))),
      ),
      child: Row(
        children: [
          // Tappable avatar opens drawer
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4E8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person_outline, color: AppColors.brandGreen),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF1C1919),
                      ),
                ),
                Text(
                  agentName,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1919),
                  ),
                ),
              ],
            ),
          ),
          // Notifications
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: IconButton(
              tooltip: 'Updates'.tr,
              onPressed: () => context.go('/updates'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TaskCard ─────────────────────────────────────────────────────────────────

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADCE0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14.1,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Name — Roboto 600 18px (Figma spec)
          Text(
            task.title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 8),
          // Description — Roboto 400 14px
          Text(
            task.subtitle,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1C1B1F),
            ),
          ),
          // Take Action button right-aligned — Roboto 500 16px #4F8506
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(task.route),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4F8506),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              ),
              child: Text(
                task.actionLabel,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
