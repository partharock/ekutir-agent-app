import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/farmer.dart';
import '../models/procurement.dart';
import '../models/support.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final trackerFarmers = appState.priorityFarmers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          appState.agentName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showMockSnackBar(
                      context,
                      'Notifications are not configured in this build.',
                    ),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Portfolio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    InfoPair(label: 'Crop', value: appState.agentCrop),
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
              const SizedBox(height: 20),
              Text('Snapshot', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricCard(
                    title: 'TOTAL LAND',
                    value: appState.totalLandAcres.toStringAsFixed(0),
                    suffix: 'Acres',
                    icon: Icons.crop_square_outlined,
                  ),
                  MetricCard(
                    title: 'TASKS TODAY',
                    value: '${appState.tasksToday}',
                    icon: Icons.rule_folder_outlined,
                  ),
                  MetricCard(
                    title: 'WILLING',
                    value: '${appState.willingCount}',
                    icon: Icons.local_offer_outlined,
                  ),
                  MetricCard(
                    title: 'BOOKED',
                    value: '${appState.bookedCount}',
                    icon: Icons.event_available_outlined,
                  ),
                  MetricCard(
                    title: 'GROWTH',
                    value: '${appState.growthCount}',
                    icon: Icons.grass_outlined,
                  ),
                  MetricCard(
                    title: 'HARVEST',
                    value: '${appState.harvestCount}',
                    icon: Icons.agriculture_outlined,
                  ),
                  MetricCard(
                    title: 'PROCUREMENT',
                    value: '${appState.procurementCount}',
                    icon: Icons.local_shipping_outlined,
                  ),
                  MetricCard(
                    title: 'SETTLEMENT',
                    value: '${appState.settlementCount}',
                    icon: Icons.task_alt_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Today\'s Priorities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (appState.homeTasks.isEmpty)
                const EmptyStateCard(
                  message: 'No urgent workflow items are pending today.',
                )
              else
                ...appState.homeTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(task: task),
                  ),
                ),
              const SizedBox(height: 16),
              SectionCard(
                backgroundColor: AppColors.brandBlueLight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MISA AI',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ask for the next action, pending OTPs, or settlement readiness.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => context.go('/misa-ai'),
                            child: const Text('Open assistant'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Farmer-wise Tracking',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...trackerFarmers.map(
                (farmer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FarmerTrackerCard(farmer: farmer),
                ),
              ),
            ],
          ),
        ),
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
    this.suffix,
  });

  final String title;
  final String value;
  final String? suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return SizedBox(
      width: width,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 4,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.brandGreen,
                      ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      suffix!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brandGreen,
                          ),
                    ),
                  ),
              ],
            ),
          ],
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(
                label: task.statusLabel,
                background: task.priority.color.withValues(alpha: 0.12),
                foreground: task.priority.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
    final appState = context.watch<AppState>();
    final procurementSteps = appState.farmerTrackerProcurementSteps(farmer.id);
    final nextTask = appState.nextTaskForFarmer(farmer.id);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  farmer.name,
                  style: Theme.of(context).textTheme.titleMedium,
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
          InfoPair(label: 'Location', value: farmer.location),
          const SizedBox(height: 8),
          InfoPair(label: 'Cash', value: appState.farmerTrackerSupportLabel(farmer.id, SupportType.cash)),
          const SizedBox(height: 8),
          InfoPair(label: 'Kind', value: appState.farmerTrackerSupportLabel(farmer.id, SupportType.kind)),
          const SizedBox(height: 8),
          InfoPair(label: 'Procurement', value: appState.farmerTrackerProcurementLabel(farmer.id)),
          if (nextTask != null) ...[
            const SizedBox(height: 8),
            InfoPair(label: 'Next Action', value: nextTask.title),
          ],
          if (procurementSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: procurementSteps
                  .map(
                    (step) => StatusPill(
                      label: step.label,
                      background: AppColors.brandBlueLight,
                      foreground: AppColors.brandBlue,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (nextTask != null)
                FilledButton(
                  style: filledButtonStyle(),
                  onPressed: () => context.go(nextTask.route),
                  child: Text(nextTask.actionLabel),
                ),
              OutlinedButton(
                onPressed: () => context.go('/engage/farmer/${farmer.id}?tab=profile'),
                child: const Text('View Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.danger;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.brandBlue;
    }
  }
}
