import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
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
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: const BoxDecoration(color: AppColors.brandBlueLight),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    appState.agentName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.brandBlue,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appState.agentType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appState.agentOrg,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.brandBlue,
                        ),
                  ),
                ],
              ),
            ),
            // ── Details ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 16),
                  _ProfileDetailItem(
                    icon: Icons.badge_outlined,
                    title: 'Agent ID'.tr,
                    value: 'AGN-89234',
                  ),
                  _ProfileDetailItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number'.tr,
                    value: '+91 98765 43210',
                  ),
                  _ProfileDetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Locality'.tr,
                    value: appState.locality,
                  ),
                  _ProfileDetailItem(
                    icon: Icons.agriculture_outlined,
                    title: 'Primary Crop'.tr,
                    value: appState.agentCrop,
                  ),
                  _ProfileDetailItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Crop Duration'.tr,
                    value: appState.cropDuration,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // ── Target Progress ─────────────────────────────────
                  Text(
                    'Season Target'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _TargetProgressRow(
                    icon: Icons.groups_outlined,
                    label: 'Farmers'.tr,
                    achieved: farmerAchieved,
                    target: appState.targetFarmers,
                    progress: farmerProgress,
                    unit: '',
                  ),
                  const SizedBox(height: 12),
                  _TargetProgressRow(
                    icon: Icons.crop_square_outlined,
                    label: 'Land'.tr,
                    achieved: landAchieved.toInt(),
                    target: appState.targetLandAcres.toInt(),
                    progress: landProgress,
                    unit: 'ac',
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                    title: Text(
                      'Log Out'.tr,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(),
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

// ─── _ProfileDetailItem ───────────────────────────────────────────────────────

class _ProfileDetailItem extends StatelessWidget {
  const _ProfileDetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _TargetProgressRow ───────────────────────────────────────────────────────

class _TargetProgressRow extends StatelessWidget {
  const _TargetProgressRow({
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
    final pct = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '$achieved${unit.isNotEmpty ? ' $unit' : ''} / $target${unit.isNotEmpty ? ' $unit' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              '$pct%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: progress >= 1.0 ? AppColors.brandGreenDark : AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.brandGreen : AppColors.brandBlue,
            ),
          ),
        ),
      ],
    );
  }
}
