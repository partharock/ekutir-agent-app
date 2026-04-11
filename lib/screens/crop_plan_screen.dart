import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/crop_plan.dart';
import '../models/farmer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

enum _CropPlanFilter { all, nursery, growth, harvest, procurement }

class CropPlanScreen extends StatefulWidget {
  const CropPlanScreen({super.key, this.farmerId});

  final String? farmerId;

  @override
  State<CropPlanScreen> createState() => _CropPlanScreenState();
}

class _CropPlanScreenState extends State<CropPlanScreen> {
  String _query = '';
  _CropPlanFilter _filter = _CropPlanFilter.all;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (widget.farmerId != null) {
      final farmer = appState.farmerById(widget.farmerId!);
      return _FarmerCropPlanDetail(farmer: farmer);
    }

    final farmers = appState.priorityFarmers.where((farmer) {
      final normalized = _query.trim().toLowerCase();
      final matchesQuery = normalized.isEmpty ||
          farmer.name.toLowerCase().contains(normalized) ||
          farmer.location.toLowerCase().contains(normalized);
      final matchesFilter = switch (_filter) {
        _CropPlanFilter.all => true,
        _CropPlanFilter.nursery =>
          farmer.stage == FarmerStage.booked || farmer.stage == FarmerStage.nursery,
        _CropPlanFilter.growth => farmer.stage == FarmerStage.growth,
        _CropPlanFilter.harvest => farmer.stage == FarmerStage.harvest,
        _CropPlanFilter.procurement =>
          farmer.stage == FarmerStage.procurement ||
              appState.procurementFor(farmer.id).isNotEmpty,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    return PageScaffold(
      title: 'Crop Plan'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search farmer name, location...'.tr,
            onChanged: (value) => setState(() {
              _query = value;
            }),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StageTab(
                  label: 'All'.tr,
                  selected: _filter == _CropPlanFilter.all,
                  onTap: () => setState(() {
                    _filter = _CropPlanFilter.all;
                  }),
                ),
                const SizedBox(width: 10),
                _StageTab(
                  label: 'Nursery'.tr,
                  selected: _filter == _CropPlanFilter.nursery,
                  onTap: () => setState(() {
                    _filter = _CropPlanFilter.nursery;
                  }),
                ),
                const SizedBox(width: 10),
                _StageTab(
                  label: 'Growth'.tr,
                  selected: _filter == _CropPlanFilter.growth,
                  onTap: () => setState(() {
                    _filter = _CropPlanFilter.growth;
                  }),
                ),
                const SizedBox(width: 10),
                _StageTab(
                  label: 'Harvest'.tr,
                  selected: _filter == _CropPlanFilter.harvest,
                  onTap: () => setState(() {
                    _filter = _CropPlanFilter.harvest;
                  }),
                ),
                const SizedBox(width: 10),
                _StageTab(
                  label: 'Procurement'.tr,
                  selected: _filter == _CropPlanFilter.procurement,
                  onTap: () => setState(() {
                    _filter = _CropPlanFilter.procurement;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('All Farmers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (farmers.isEmpty)
            EmptyStateCard(
              message: 'No farmers match the current crop plan filter.'.tr,
            )
          else
            ...farmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CropPlanFarmerCard(farmer: farmer),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageTab extends StatelessWidget {
  const _StageTab({
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

class _CropPlanFarmerCard extends StatelessWidget {
  const _CropPlanFarmerCard({required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: InkWell(
        onTap: () => context.go('/crop-plan?farmerId=${farmer.id}'),
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
                  label: farmer.stage.label,
                  background: stageBackgroundColor(farmer.stage),
                  foreground: stageForegroundColor(farmer.stage),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoPair(label: 'Phone'.tr, value: farmer.phone),
            const SizedBox(height: 8),
            InfoPair(label: 'Location'.tr, value: farmer.location),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Land Area'.tr,
              value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerCropPlanDetail extends StatelessWidget {
  const _FarmerCropPlanDetail({required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activities = appState.activitiesFor(farmer.id);
    final harvestDates = appState.harvestDateOptionsFor(farmer.id);

    return PageScaffold(
      title: 'Farmer Crop Plan'.tr,
      showBack: true,
      onBack: () => context.go('/crop-plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farmer Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoPair(label: 'Stage'.tr, value: farmer.stage.label),
                const SizedBox(height: 10),
                InfoPair(label: 'Full Name'.tr, value: farmer.name),
                const SizedBox(height: 10),
                InfoPair(label: 'Mobile Number'.tr, value: farmer.phone),
                const SizedBox(height: 10),
                InfoPair(label: 'Address'.tr, value: farmer.location),
                const SizedBox(height: 10),
                FarmerPlotLocationSection(farmer: farmer),
                const SizedBox(height: 10),
                InfoPair(
                  label: 'Total Land'.tr,
                  value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
                ),
                const SizedBox(height: 10),
                InfoPair(label: 'Season'.tr, value: farmer.season),
                const SizedBox(height: 10),
                InfoPair(label: 'Crop'.tr, value: farmer.crop),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            backgroundColor: AppColors.heroMist,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stage Promotion Rules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandGreenDark,
                      ),
                ),
                const SizedBox(height: 12),
                Text('Nursery Start in progress or completed -> Nursery'.tr),
                const SizedBox(height: 6),
                Text('Transplanting completed -> Growth'.tr),
                const SizedBox(height: 6),
                Text('Harvest Window Start active -> Harvest'.tr),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (harvestDates.isNotEmpty)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harvest Date Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: harvestDates
                        .map(
                          (date) => StatusPill(
                            label: formatDate(date),
                            background: AppColors.brandBlueLight,
                            foreground: AppColors.brandBlue,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          if (harvestDates.isNotEmpty) const SizedBox(height: 16),
          Text(
            'Planned Activities',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityTimelineCard(
                farmerId: farmer.id,
                activity: activity,
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
    required this.farmerId,
    required this.activity,
  });

  final String farmerId;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                        'Planned: ${formatDate(activity.plannedDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.detail,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CropActivityStatus.values
                  .map(
                    (status) => ChoiceChip(
                      label: Text(status.label),
                      selected: activity.status == status,
                      onSelected: (_) {
                        context
                            .read<AppState>()
                            .updateCropActivityStatus(farmerId, activity.id, status);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
