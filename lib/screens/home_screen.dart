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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.homeTasks.take(3).toList();

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
                    const SizedBox(height: 16),

                    // MISA AI Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MisaAiCard(),
                    ),
                    const SizedBox(height: 16),

                    // Today's Activities section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Today's Activities",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1B1F),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          // Activity Name
          Text(
            task.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1F),
                ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            task.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF1C1B1F),
                ),
          ),
          // Take Action button right-aligned
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

