import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/crop_plan.dart';
import '../models/farmer.dart';
import '../models/procurement.dart';
import '../models/settlement.dart';
import '../models/support.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

enum FarmerDirectoryTab { willing, booked, all }

class EngagementScreen extends StatefulWidget {
  const EngagementScreen({super.key, this.initialTab = FarmerDirectoryTab.willing});

  final FarmerDirectoryTab initialTab;

  @override
  State<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends State<EngagementScreen> {
  String _query = '';
  late FarmerDirectoryTab _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.searchFarmers(_query).where((farmer) {
      switch (_filter) {
        case FarmerDirectoryTab.willing:
          return farmer.status == FarmerStatus.willing;
        case FarmerDirectoryTab.booked:
          return farmer.status == FarmerStatus.booked;
        case FarmerDirectoryTab.all:
          return true;
      }
    }).toList();

    return PageScaffold(
      title: 'Engage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search farmer name, location...',
            onChanged: (value) => setState(() {
              _query = value;
            }),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DirectoryTabChip(
                  label: 'Willing Farmers',
                  selected: _filter == FarmerDirectoryTab.willing,
                  onTap: () => setState(() {
                    _filter = FarmerDirectoryTab.willing;
                  }),
                ),
                const SizedBox(width: 10),
                _DirectoryTabChip(
                  label: 'Booked Farmers',
                  selected: _filter == FarmerDirectoryTab.booked,
                  onTap: () => setState(() {
                    _filter = FarmerDirectoryTab.booked;
                  }),
                ),
                const SizedBox(width: 10),
                _DirectoryTabChip(
                  label: 'All Farmers',
                  selected: _filter == FarmerDirectoryTab.all,
                  onTap: () => setState(() {
                    _filter = FarmerDirectoryTab.all;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            switch (_filter) {
              FarmerDirectoryTab.willing => 'Willing Farmers',
              FarmerDirectoryTab.booked => 'Booked Farmers',
              FarmerDirectoryTab.all => 'All Farmers',
            },
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          if (farmers.isEmpty)
            const EmptyStateCard(
              message: 'No farmers match the selected engage filter.',
            )
          else
            ...farmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FarmerListCard(
                  farmer: farmer,
                  onTap: () => context.go('/engage/farmer/${farmer.id}?tab=profile'),
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
      onBack: () => context.go(
        switch (farmer.status) {
          FarmerStatus.willing => '/engage?tab=willing',
          FarmerStatus.booked => '/engage?tab=booked',
        },
      ),
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
                        style: Theme.of(context).textTheme.titleLarge,
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
                Text(
                  '${farmer.crop} • ${farmer.season}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final success = await appState.callFarmer(farmer.id);
                        if (context.mounted) {
                          showMockSnackBar(
                            context,
                            success ? 'Dialer opened.' : 'Unable to open dialer.',
                          );
                        }
                      },
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final success = await appState.messageFarmer(
                          farmer.id,
                          body:
                              'Hello ${farmer.name}, this is your eK Acre field agent.',
                        );
                        if (context.mounted) {
                          showMockSnackBar(
                            context,
                            success ? 'Messaging app opened.' : 'Unable to open messaging app.',
                          );
                        }
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Message'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final success = await appState.shareFarmerSummary(farmer.id);
                        if (context.mounted) {
                          showMockSnackBar(
                            context,
                            success ? 'Summary shared.' : 'Unable to share summary.',
                          );
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
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
                  child: _DirectoryTabChip(
                    label: 'Farmer Profile',
                    selected: !isCultivationTab,
                    onTap: () => context.go('/engage/farmer/$farmerId?tab=profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DirectoryTabChip(
                    label: 'Cultivation',
                    selected: isCultivationTab,
                    onTap: () => context.go('/engage/farmer/$farmerId?tab=cultivation'),
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
    final appState = context.watch<AppState>();
    final timeline = appState.timelineFor(farmer.id);
    final supportHistory = appState.supportFor(farmer.id);
    final pendingSupport = appState.pendingSupportFor(farmer.id);
    final finalizedSupport = appState.finalizedSupportFor(farmer.id);
    final procurementHistory = appState.procurementFor(farmer.id);
    final settlement = appState.settlementPreviewFor(farmer.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
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
              InfoPair(label: 'Land Details', value: farmer.landDetails),
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
                'Support He Will Get',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...farmer.supportPreview.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InfoPair(label: entry.key, value: entry.value),
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
                'Settlement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              InfoPair(label: 'Status', value: settlement.status.label),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Support Value',
                value: currency(settlement.supportValue),
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Procurement Value',
                value: currency(settlement.procurementValue),
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Net Settlement',
                value: currency(settlement.netSettlement),
              ),
              const SizedBox(height: 12),
              if (settlement.status == SettlementStatus.pendingReconciliation)
                Text(
                  appState.canCompleteSettlement(farmer.id)
                      ? 'Reconciliation can be completed now.'
                      : 'Pending reconciliation. All support records must be acknowledged and procurement must be submitted first.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (appState.canCompleteSettlement(farmer.id) &&
                  settlement.status != SettlementStatus.completed) ...[
                const SizedBox(height: 12),
                FilledButton(
                  style: filledButtonStyle(),
                  onPressed: () {
                    final success = appState.completeSettlement(farmer.id);
                    showMockSnackBar(
                      context,
                      success
                          ? 'Settlement completed.'
                          : 'Settlement is not ready yet.',
                    );
                  },
                  child: const Text('Complete Settlement'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction / Activity Timeline',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...timeline.take(6).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TimelineTile(entry: entry),
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
                'Pending Support Records',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (pendingSupport.isEmpty)
                Text(
                  settlement.status == SettlementStatus.completed
                      ? 'No pending support records.'
                      : 'Pending reconciliation',
                )
              else
                ...pendingSupport.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SupportRecordTile(record: item),
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
                'Disbursement History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (finalizedSupport.isEmpty)
                Text(
                  supportHistory.isEmpty
                      ? 'No support records yet.'
                      : 'History will appear here after reconciliation is completed.',
                )
              else
                ...finalizedSupport.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SupportRecordTile(record: item),
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
              if (procurementHistory.isEmpty)
                const Text('No procurement records yet.')
              else
                ...procurementHistory.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProcurementRecordTile(record: item),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StageActionPanel(farmer: farmer),
      ],
    );
  }
}

class CultivationTab extends StatelessWidget {
  const CultivationTab({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activities = appState.activitiesFor(farmer.id);

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
              InfoPair(
                label: 'Nursery Land',
                value: '${farmer.nurseryLandAcres.toStringAsFixed(1)} acres',
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Main Crop Land',
                value: '${farmer.mainLandAcres.toStringAsFixed(1)} acres',
              ),
              const SizedBox(height: 8),
              InfoPair(label: 'Crop', value: farmer.crop),
              const SizedBox(height: 8),
              InfoPair(label: 'Season', value: farmer.season),
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
              ...activities.take(4).map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivityCard(activity: activity),
                    ),
                  ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/crop-plan?farmerId=${farmer.id}'),
                  child: const Text('Open full crop plan'),
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
  });

  final FarmerProfile farmer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return SectionCard(
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
                  label: farmer.status == FarmerStatus.willing
                      ? farmer.status.label
                      : farmer.stage.label,
                  background: farmer.status == FarmerStatus.willing
                      ? farmer.status.backgroundColor
                      : stageBackgroundColor(farmer.stage),
                  foreground: farmer.status == FarmerStatus.willing
                      ? farmer.status.foregroundColor
                      : stageForegroundColor(farmer.stage),
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
              value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: appState.farmerTrackerSupportLabel(farmer.id, SupportType.cash),
                  background: AppColors.brandBlueLight,
                  foreground: AppColors.brandBlue,
                ),
                StatusPill(
                  label: appState.farmerTrackerSupportLabel(farmer.id, SupportType.kind),
                  background: AppColors.brandGreenLight,
                  foreground: AppColors.brandGreenDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryTabChip extends StatelessWidget {
  const _DirectoryTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.heroMist,
      side: BorderSide(
        color: selected ? AppColors.brandGreen : AppColors.cardBorder,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.brandGreenDark : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
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
      FarmerStage.settlementCompleted,
    ];
    final currentIndex = stages.indexOf(currentStage);
    return Row(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isActive = index <= currentIndex;
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
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentIndex
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stage.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});

  final FarmerTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.brandGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(entry.detail, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                '${formatDate(entry.date)} • ${entry.statusLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportRecordTile extends StatelessWidget {
  const _SupportRecordTile({required this.record});

  final SupportRecord record;

  @override
  Widget build(BuildContext context) {
    final value = record.type == SupportType.cash
        ? currency(record.cashAmount ?? 0)
        : '${record.itemName} • ${record.quantity?.toStringAsFixed(0)} ${record.unit}';
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
                    record.type.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusPill(
                  label: record.statusLabel,
                  background: record.isAcknowledged
                      ? AppColors.brandGreenLight
                      : AppColors.brandBlueLight,
                  foreground: record.isAcknowledged
                      ? AppColors.brandGreenDark
                      : AppColors.brandBlue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InfoPair(label: 'Value', value: value),
            const SizedBox(height: 8),
            InfoPair(label: 'Context', value: record.cropContext),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Reconciliation',
              value: record.finalized ? 'Finalized' : 'In progress',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcurementRecordTile extends StatelessWidget {
  const _ProcurementRecordTile({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
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
                    record.receiptNumber ?? 'Procurement Draft',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusPill(
                  label: record.submitted ? 'Submitted' : 'In Progress',
                  background: record.submitted
                      ? AppColors.brandGreenLight
                      : AppColors.brandBlueLight,
                  foreground: record.submitted
                      ? AppColors.brandGreenDark
                      : AppColors.brandBlue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Harvest Date',
              value: record.selectedHarvestDate == null
                  ? '-'
                  : formatDate(record.selectedHarvestDate!),
            ),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Final Quantity',
              value: '${(record.finalWeighingQtyKg ?? 0).toStringAsFixed(0)} kg',
            ),
            const SizedBox(height: 8),
            InfoPair(label: 'Total', value: currency(record.totalAmount)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final CropPlanActivity activity;

  @override
  Widget build(BuildContext context) {
    final color = switch (activity.status) {
      CropActivityStatus.planned => AppColors.textSecondary,
      CropActivityStatus.inProgress => AppColors.warning,
      CropActivityStatus.completed => AppColors.brandGreen,
    };
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
                  label: activity.status.label,
                  background: color.withValues(alpha: 0.12),
                  foreground: color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatDate(activity.plannedDate),
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

class _StageActionPanel extends StatelessWidget {
  const _StageActionPanel({required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settlement = appState.settlementPreviewFor(farmer.id);

    final buttons = <Widget>[];
    if (farmer.status == FarmerStatus.willing) {
      buttons.add(
        FilledButton(
          key: const Key('start_cash_advance_button'),
          style: filledButtonStyle(),
          onPressed: () => context.go('/support/flow/cash?farmerId=${farmer.id}'),
          child: const Text('Proceed To Booking'),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () => context.go('/support/flow/cash?farmerId=${farmer.id}'),
          child: const Text('Start Cash Advance'),
        ),
      );
    } else {
      buttons.add(
        FilledButton(
          style: filledButtonStyle(),
          onPressed: () => context.go('/support/flow/kind?farmerId=${farmer.id}'),
          child: const Text('Give Kind Support'),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () => context.go('/crop-plan?farmerId=${farmer.id}'),
          child: const Text('Open Crop Plan'),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () => context.go('/harvest/procurement?farmerId=${farmer.id}'),
          child: const Text('Start Procurement'),
        ),
      );
      if (appState.canCompleteSettlement(farmer.id) &&
          settlement.status != SettlementStatus.completed) {
        buttons.add(
          OutlinedButton(
            onPressed: () {
              final success = appState.completeSettlement(farmer.id);
              showMockSnackBar(
                context,
                success ? 'Settlement completed.' : 'Settlement is not ready yet.',
              );
            },
            child: const Text('Complete Settlement'),
          ),
        );
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: buttons,
    );
  }
}
