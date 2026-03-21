import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../models/farmer.dart';
import '../models/crop_plan.dart';
import '../utils/formatters.dart';

class CropPlanScreen extends StatelessWidget {
  const CropPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmer = context.watch<AppState>().featuredFarmer;

    return PageScaffold(
      title: 'Farmer Crop Plan',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farmer Details', style: Theme.of(context).textTheme.titleLarge),
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
                      style: Theme.of(context).textTheme.titleMedium,
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
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...farmer.activities.asMap().entries.map(
                (entry) => Padding(
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
                color: color.withValues(alpha: 0.12),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusPill(
                  label: activity.status,
                  background: statusColor.withValues(alpha: 0.12),
                  foreground: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Planned: ${formatDate(activity.plannedDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(activity.detail, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
