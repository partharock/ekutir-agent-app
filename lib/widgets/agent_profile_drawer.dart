import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/translation_service.dart';

class AgentProfileDrawer extends StatelessWidget {
  const AgentProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmerAchieved = appState.farmers.length;
    final landAchieved = appState.totalLandAcres;
    final farmerProgress = (farmerAchieved / appState.targetFarmers).clamp(0.0, 1.0);
    final landProgress = (landAchieved / appState.targetLandAcres).clamp(0.0, 1.0);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Section ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FF),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFE5F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.42),
                    ),
                    child: const Icon(Icons.person, size: 40, color: Color(0xFF294190)),
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    appState.agentName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF294190),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF294190),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      appState.agentType,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Org
                  Text(
                    appState.agentOrg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1C1919),
                    ),
                  ),
                ],
              ),
            ),

            // ── Details List ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'agent id'.tr,
                    value: 'AGN-89234',
                  ),
                  _DrawerDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'phone number'.tr,
                    value: '+91 12345 56789',
                  ),
                  _DrawerDetailRow(
                    icon: Icons.mail_outline,
                    label: 'email address'.tr,
                    value: 'ravi@domain.com',
                  ),
                  _DrawerDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'location'.tr,
                    value: appState.locality,
                  ),
                  _DrawerDetailRow(
                    icon: Icons.domain_outlined,
                    label: 'organization name'.tr,
                    value: appState.agentOrg,
                  ),
                  _DrawerDetailRow(
                    icon: Icons.agriculture_outlined,
                    label: 'CROP'.tr,
                    value: appState.agentCrop,
                  ),
                  _DrawerDetailRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'CROP DURATION'.tr,
                    value: appState.cropDuration,
                  ),

                  const Divider(height: 32, indent: 16, endIndent: 16),

                  // ── Target Tracker ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Target Tracker'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1B1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _TargetTrackerCard(
                    icon: Icons.person_outline,
                    label: 'Farmer Target'.tr,
                    achieved: farmerAchieved,
                    target: appState.targetFarmers,
                    progress: farmerProgress,
                    unit: '',
                  ),
                  const SizedBox(height: 12),
                  _TargetTrackerCard(
                    icon: Icons.map_outlined,
                    label: 'Land Target'.tr,
                    achieved: landAchieved.toInt(),
                    target: appState.targetLandAcres.toInt(),
                    progress: landProgress,
                    unit: 'ac',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer Row ───────────────────────────────────────────────────────────────

class _DrawerDetailRow extends StatelessWidget {
  const _DrawerDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF1C1B1F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toLowerCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Target Tracker Card ─────────────────────────────────────────────────────

class _TargetTrackerCard extends StatelessWidget {
  const _TargetTrackerCard({
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1C1B1F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
              ),
              Text(
                '$achieved$u / $target$u',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1B1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Stack(
            children: [
              // Background track
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(33),
                ),
              ),
              // Fill
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
