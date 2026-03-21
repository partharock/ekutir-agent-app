import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../models/farmer.dart';
import '../models/crop_plan.dart';
import '../models/support.dart';
import '../models/procurement.dart';
import '../utils/formatters.dart';
import 'harvest_screens.dart';

class EngagementScreen extends StatefulWidget {
  const EngagementScreen({super.key});

  @override
  State<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends State<EngagementScreen> {
  String _query = '';
  FarmerStatus _filter = FarmerStatus.willing;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.searchFarmers(_query, status: _filter);
    final heading =
        _filter == FarmerStatus.willing ? 'Willing Farmers' : 'Booked Farmers';

    return PageScaffold(
      title: 'Engage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search...',
            onChanged: (value) => setState(() {
              _query = value;
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilterPill(
                  label: 'Willing Farmers',
                  selected: _filter == FarmerStatus.willing,
                  onTap: () => setState(() {
                    _filter = FarmerStatus.willing;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilterPill(
                  label: 'Booked Farmers',
                  selected: _filter == FarmerStatus.booked,
                  onTap: () => setState(() {
                    _filter = FarmerStatus.booked;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(heading, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (farmers.isEmpty)
            const EmptyStateCard(
              message: 'No farmers match the current filter.',
            )
          else
            ...farmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FarmerListCard(
                  farmer: farmer,
                  onTap: () => context.push('/engage/farmer/${farmer.id}'),
                  statusLabel: _filter == FarmerStatus.booked
                      ? farmer.stage.label
                      : farmer.status.label,
                  statusBackground: _filter == FarmerStatus.booked
                      ? stageBackgroundColor(farmer.stage)
                      : null,
                  statusForeground: _filter == FarmerStatus.booked
                      ? stageForegroundColor(farmer.stage)
                      : null,
                  showViewDetails: false,
                  footer: FarmerCardFooter(
                    showSupportChips: _filter == FarmerStatus.booked,
                    cashAcknowledged: farmer.supportHistory.any(
                      (item) => item.type == SupportType.cash,
                    ),
                    kindAcknowledged: farmer.supportHistory.any(
                      (item) => item.type == SupportType.kind,
                    ),
                    onCall: () => showMockSnackBar(
                      context,
                      'Calling is mocked in v1.',
                    ),
                    onMessage: () => showMockSnackBar(
                      context,
                      'Messaging is mocked in v1.',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({
    super.key,
    required this.farmerId,
    required this.initialTab,
  });

  final String farmerId;
  final String initialTab;

  bool get isCultivationTab => initialTab == 'cultivation';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmer = appState.farmerById(farmerId);
    final showCultivationTab = farmer.status == FarmerStatus.booked;

    return PageScaffold(
      title: 'Farmer Profile',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
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
                      label: farmer.status.label,
                      background: farmer.status.backgroundColor,
                      foreground: farmer.status.foregroundColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showMockSnackBar(
                          context,
                          'Calling is mocked in v1.',
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showMockSnackBar(
                          context,
                          'Messaging is mocked in v1.',
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (showCultivationTab) ...[
            Row(
              children: [
                Expanded(
                  child: FilterPill(
                    label: 'Farmer Profile',
                    selected: !isCultivationTab,
                    onTap: () => context.go(
                      '/engage/farmer/$farmerId?tab=profile',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilterPill(
                    label: 'Cultivation',
                    selected: isCultivationTab,
                    onTap: () => context.go(
                      '/engage/farmer/$farmerId?tab=cultivation',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (showCultivationTab && isCultivationTab)
            CultivationTab(farmer: farmer)
          else
            ProfileTab(farmer: farmer),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
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
              InfoPair(label: 'Crop', value: farmer.crop),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stage Tracker',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              StageProgressBar(currentStage: farmer.stage),
              const SizedBox(height: 10),
              Text(
                stageHelperText(farmer.stage),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Coverage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Support details are provided by the system based on partnership farming terms.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Support',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      InfoPair(
                        label: 'Cash Advance Eligibility',
                        value: 'Up to ${currency(farmer.cashEligibility)} INR',
                      ),
                      const SizedBox(height: 8),
                      const InfoPair(label: 'Purpose', value: 'Lorem Ipsum'),
                      const SizedBox(height: 8),
                      const InfoPair(
                        label: 'Disbursement Method',
                        value: 'OTP confirmation required',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kind Support',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ...farmer.kindSupportItems.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InfoPair(label: entry.key, value: entry.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (farmer.status == FarmerStatus.booked) ...[
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity Timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...farmer.activities.take(3).map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TimelineRow(activity: activity),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => context.go('/crop-plan'),
                    child: const Text('View Full History'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disbursement History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (farmer.supportHistory.isEmpty)
                const Text('No data available')
              else
                ...farmer.supportHistory.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SupportHistoryTile(transaction: item),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Procurement History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (farmer.procurementHistory.isEmpty)
                const Text('No data available')
              else
                ...farmer.procurementHistory.map(
                  (receipt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProcurementHistoryTile(receipt: receipt),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('book_farmer_button'),
          style: filledButtonStyle(),
          onPressed: () {
            if (farmer.status == FarmerStatus.willing) {
              context.read<AppState>().bookFarmer(farmer.id);
              showMockSnackBar(
                context,
                '${farmer.name} moved to booked farmers.',
              );
            } else {
              context.push('/support');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              farmer.status == FarmerStatus.willing
                  ? 'Book Farmer'
                  : 'Disburse Support',
            ),
          ),
        ),
      ],
    );
  }
}

class CultivationTab extends StatelessWidget {
  const CultivationTab({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Land Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nursery Land',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InfoPair(
                        label: 'Land Area',
                        value: '${farmer.nurseryLandAcres.toStringAsFixed(0)} acres',
                      ),
                      const SizedBox(height: 8),
                      const InfoPair(
                        label: 'Location',
                        value: 'State, District, Block',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                useInnerPadding: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Main Crop Land',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InfoPair(
                        label: 'Land Area',
                        value: '${farmer.mainLandAcres.toStringAsFixed(0)} acres',
                      ),
                      const SizedBox(height: 8),
                      const InfoPair(
                        label: 'Location',
                        value: 'State, District, Block',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Planning',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...farmer.activities.take(3).map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivityCard(activity: activity),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => context.go('/crop-plan'),
                  child: const Text('View full crop plan'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pre-Harvest Activity Tracker',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...farmer.activities.take(2).map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TimelineRow(activity: activity),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FarmerListCard extends StatelessWidget {
  const FarmerListCard({
    super.key,
    required this.farmer,
    this.onTap,
    this.selected = false,
    this.statusLabel,
    this.statusBackground,
    this.statusForeground,
    this.footer,
    this.showFooterDivider = false,
    this.showViewDetails = true,
  });

  final FarmerProfile farmer;
  final VoidCallback? onTap;
  final bool selected;
  final String? statusLabel;
  final Color? statusBackground;
  final Color? statusForeground;
  final Widget? footer;
  final bool showFooterDivider;
  final bool showViewDetails;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      highlighted: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                  label: statusLabel ?? farmer.status.label,
                  background: statusBackground ?? farmer.status.backgroundColor,
                  foreground: statusForeground ?? farmer.status.foregroundColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoPair(label: 'Phone', value: farmer.phone),
            const SizedBox(height: 8),
            InfoPair(label: 'Location', value: farmer.location),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Land Area',
              value: '${farmer.totalLandAcres.toStringAsFixed(0)} acres',
            ),
            if (footer != null) ...[
              const SizedBox(height: 12),
              if (showFooterDivider) ...[
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
              footer!,
            ] else if (onTap != null && showViewDetails) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View Details',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.brandGreenDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FarmerCardFooter extends StatelessWidget {
  const FarmerCardFooter({
    super.key,
    this.showSupportChips = false,
    this.cashAcknowledged = true,
    this.kindAcknowledged = true,
    this.onCall,
    this.onMessage,
  });

  final bool showSupportChips;
  final bool cashAcknowledged;
  final bool kindAcknowledged;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSupportChips) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HistoryChip(
                label:
                    kindAcknowledged ? 'Kind: Acknowledged' : 'Kind: Pending',
              ),
              HistoryChip(
                label:
                    cashAcknowledged ? 'Cash: Acknowledged' : 'Cash: Pending',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onCall,
              icon: const Icon(
                Icons.call_outlined,
                color: AppColors.brandGreenDark,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onMessage,
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.brandGreenDark,
                size: 18,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ],
        ),
      ],
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.brandGreenDark,
          ),
        ),
      ),
    );
  }
}

class StageProgressBar extends StatelessWidget {
  const StageProgressBar({super.key, required this.currentStage});

  final FarmerStage currentStage;

  @override
  Widget build(BuildContext context) {
    final stages = [
      FarmerStage.willing,
      FarmerStage.booked,
      FarmerStage.nursery,
      FarmerStage.growth,
      FarmerStage.harvest,
      FarmerStage.procurement,
      FarmerStage.completed,
    ];
    final currentIndex = stages.indexWhere((stage) => stage == currentStage);

    return Row(
      children: List.generate(stages.length, (index) {
        final isActive = index <= (currentIndex == -1 ? 0 : currentIndex);
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                            isActive ? AppColors.brandGreen : AppColors.cardBorder,
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.brandGreen : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < (currentIndex == -1 ? 0 : currentIndex)
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stages[index].label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.activity});

  final CropPlanActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                activity.completed ? AppColors.brandGreen : AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(activity.status, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class SupportHistoryTile extends StatelessWidget {
  const SupportHistoryTile({super.key, required this.transaction});

  final SupportTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amountOrItem = transaction.type == SupportType.cash
        ? currency(transaction.amount ?? 0)
        : (transaction.itemName ?? 'Item');
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.type.label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          amountOrItem,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class ProcurementHistoryTile extends StatelessWidget {
  const ProcurementHistoryTile({super.key, required this.receipt});

  final ProcurementReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            receipt.receiptNo,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          currency(receipt.totalAmount),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
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
