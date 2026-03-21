import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../models/farmer.dart';
import '../models/support.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final trackerFarmers = appState.bookedFarmers.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brandGreenLight,
                  child: Icon(
                    Icons.person,
                    color: AppColors.brandGreenDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        appState.agentName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showMockSnackBar(
                    context,
                    'Notifications are mocked in v1.',
                  ),
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
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
                  const InfoPair(label: 'Crop', value: 'Rice'),
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricCard(
                  title: 'Total Land',
                  value: '${appState.totalLandAcres.toStringAsFixed(0)} Acres',
                  icon: Icons.grid_view_outlined,
                ),
                MetricCard(
                  title: 'Tasks Today',
                  value: '${appState.tasksToday}',
                  icon: Icons.assignment_outlined,
                ),
                MetricCard(
                  title: 'Willing Farmers',
                  value: '${appState.willingCount}',
                  icon: Icons.favorite_outline,
                ),
                MetricCard(
                  title: 'Booked Farmers',
                  value: '${appState.bookedCount}',
                  icon: Icons.check_circle_outline,
                ),
                MetricCard(
                  title: 'Nursery',
                  value: '${appState.nurseryCount}',
                  icon: Icons.spa_outlined,
                ),
                MetricCard(
                  title: 'Transplanted',
                  value: '${appState.transplantedCount}',
                  icon: Icons.grass_outlined,
                ),
                MetricCard(
                  title: 'Harvest',
                  value: '${appState.harvestCount}',
                  icon: Icons.agriculture_outlined,
                ),
                MetricCard(
                  title: 'Procurement',
                  value: '${appState.procurementCount}',
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Today\'s Priorities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Pending actions across farmers',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ...appState.homeTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(task: task),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Farmer Status Tracker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Latest support and transaction status per farmer',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ...trackerFarmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FarmerTrackerCard(farmer: farmer),
              ),
            ),
            if (trackerFarmers.isNotEmpty)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => context.go('/engage'),
                  child: const Text('View all farmers'),
                ),
              ),
          ],
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
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      child: SectionCard(
        useInnerPadding: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.brandGreenDark),
              ),
            ],
          ),
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
                background: AppColors.warning.withValues(alpha: 0.12),
                foreground: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HistoryChip(
                label: farmer.supportHistory.any(
                  (item) => item.type == SupportType.cash,
                )
                    ? 'Cash: Acknowledged'
                    : 'Cash: Pending',
              ),
              HistoryChip(
                label: farmer.supportHistory.any(
                  (item) => item.type == SupportType.kind,
                )
                    ? 'Kind: Acknowledged'
                    : 'Kind: Pending',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/engage/farmer/${farmer.id}'),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryChip extends StatelessWidget {
  const HistoryChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brandGreenDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

extension TaskPriorityX on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.brandBlue;
      case TaskPriority.low:
        return AppColors.brandGreen;
    }
  }
}
