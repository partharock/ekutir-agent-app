import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/crop_plan.dart';
import '../models/farmer.dart';
import '../models/procurement.dart';
import '../models/settlement.dart';
import '../models/support.dart';
import '../services/plot_location_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

enum FarmerDirectoryTab { willing, booked, all }

class EngagementScreen extends StatefulWidget {
  const EngagementScreen(
      {super.key, this.initialTab = FarmerDirectoryTab.willing});

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
      title: 'Engage'.tr,
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('add_willing_farmer_button'),
              style: filledButtonStyle(),
              onPressed: () => context.go('/engage/add'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Add Willing Farmer'.tr),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DirectoryTabChip(
                  label: 'Willing Farmers'.tr,
                  selected: _filter == FarmerDirectoryTab.willing,
                  onTap: () => setState(() {
                    _filter = FarmerDirectoryTab.willing;
                  }),
                ),
                const SizedBox(width: 10),
                _DirectoryTabChip(
                  label: 'Booked Farmers'.tr,
                  selected: _filter == FarmerDirectoryTab.booked,
                  onTap: () => setState(() {
                    _filter = FarmerDirectoryTab.booked;
                  }),
                ),
                const SizedBox(width: 10),
                _DirectoryTabChip(
                  label: 'All Farmers'.tr,
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
            EmptyStateCard(
              message: 'No farmers match the selected engage filter.'.tr,
            )
          else
            ...farmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FarmerListCard(
                  farmer: farmer,
                  onTap: () =>
                      context.go('/engage/farmer/${farmer.id}?tab=profile'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddWillingFarmerScreen extends StatefulWidget {
  const AddWillingFarmerScreen({super.key});

  @override
  State<AddWillingFarmerScreen> createState() => _AddWillingFarmerScreenState();
}

class _AddWillingFarmerScreenState extends State<AddWillingFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _cropController = TextEditingController();
  final _seasonController = TextEditingController();
  final _landDetailsController = TextEditingController();
  final _totalLandController = TextEditingController();
  final _nurseryLandController = TextEditingController();
  final _mainLandController = TextEditingController();

  bool _defaultsApplied = false;
  PlotLocation? _plotLocation;
  bool _isCapturingPlotLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied) {
      return;
    }
    _seasonController.text = context.read<AppState>().currentSeason;
    _defaultsApplied = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _cropController.dispose();
    _seasonController.dispose();
    _landDetailsController.dispose();
    _totalLandController.dispose();
    _nurseryLandController.dispose();
    _mainLandController.dispose();
    super.dispose();
  }

  double? _parseLandValue(String value) => double.tryParse(value.trim());

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _validatePhone(AppState appState, String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.'.tr;
    }
    if (appState.normalizePhoneNumber(value).isEmpty) {
      return 'Enter a valid phone number.'.tr;
    }
    if (!appState.isNormalizedPhoneAvailable(value)) {
      return 'A farmer with this phone number already exists.'.tr;
    }
    return null;
  }

  String? _validatePositiveLand(String? value, String label) {
    final parsed = _parseLandValue(value ?? '');
    if (parsed == null) {
      return 'Enter $label in acres.';
    }
    if (parsed <= 0) {
      return '$label must be greater than zero.';
    }
    return null;
  }

  String? _validateSplitTotal() {
    final total = _parseLandValue(_totalLandController.text);
    final nursery = _parseLandValue(_nurseryLandController.text);
    final main = _parseLandValue(_mainLandController.text);
    if (total == null || nursery == null || main == null) {
      return null;
    }
    final difference = (total - nursery - main).abs();
    if (difference > 0.001) {
      return 'Nursery land and main land must add up to total land.'.tr;
    }
    return null;
  }

  Future<void> _capturePlotLocation() async {
    setState(() {
      _isCapturingPlotLocation = true;
    });

    try {
      final plotLocation = await context.read<PlotLocationService>()
          .capturePlotLocation(
        context,
        locationHint: _locationController.text,
        currentLocation: _plotLocation,
      );
      if (plotLocation != null && mounted) {
        setState(() {
          _plotLocation = plotLocation;
        });
      }
    } on PlotLocationException catch (error) {
      if (mounted) {
        showMockSnackBar(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        showMockSnackBar(
          context,
          'Unable to open the plot location picker.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingPlotLocation = false;
        });
      }
    }
  }

  void _submit(AppState appState) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = NewFarmerDraft(
      name: _nameController.text,
      phone: _phoneController.text,
      location: _locationController.text,
      plotLocation: _plotLocation,
      crop: _cropController.text,
      season: _seasonController.text,
      landDetails: _landDetailsController.text,
      totalLandAcres: _parseLandValue(_totalLandController.text)!,
      nurseryLandAcres: _parseLandValue(_nurseryLandController.text)!,
      mainLandAcres: _parseLandValue(_mainLandController.text)!,
    );

    final farmer = appState.addWillingFarmer(draft);
    if (farmer == null) {
      showMockSnackBar(context, 'Unable to save farmer details.');
      return;
    }

    showMockSnackBar(context, 'Willing farmer added.');
    context.go('/engage/farmer/${farmer.id}?tab=profile');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return PageScaffold(
      title: 'Add Willing Farmer'.tr,
      showBack: true,
      description: 'Capture the farmer details for onboarding.',
      onBack: () => context.go('/engage?tab=willing'),
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('save_new_farmer_button'),
          style: filledButtonStyle(),
          onPressed: () => _submit(appState),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Save Farmer'.tr),
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('new_farmer_name_field'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) => _validateRequired(value, 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_phone_field'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Mobile Number'),
                    validator: (value) => _validatePhone(appState, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_location_field'),
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) => _validateRequired(value, 'Location'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_crop_field'),
                    controller: _cropController,
                    decoration: const InputDecoration(labelText: 'Crop'),
                    validator: (value) => _validateRequired(value, 'Crop'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_season_field'),
                    controller: _seasonController,
                    decoration: const InputDecoration(labelText: 'Season'),
                    validator: (value) => _validateRequired(value, 'Season'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_land_details_field'),
                    controller: _landDetailsController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Land Details'),
                    validator: (value) =>
                        _validateRequired(value, 'Land details'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Plot GPS Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture the exact plot point on a Mappls map. The village/location field above stays unchanged for search and list views.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('capture_plot_location_button'),
                      onPressed:
                          _isCapturingPlotLocation ? null : _capturePlotLocation,
                      icon: _isCapturingPlotLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _plotLocation == null
                                  ? Icons.location_searching_outlined
                                  : Icons.edit_location_alt_outlined,
                            ),
                      label: Text(
                        _isCapturingPlotLocation
                            ? 'Opening Map...'
                            : _plotLocation == null
                                ? 'Capture Plot on Map'
                                : 'Retake Plot Location',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Saved Plot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _plotLocation?.displayAddress ?? 'Not captured',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (_plotLocation != null) ...[
                    const SizedBox(height: 10),
                    InfoPair(
                      label: 'Coordinates'.tr,
                      value: _plotLocation!.coordinatesLabel,
                    ),
                    const SizedBox(height: 10),
                    InfoPair(
                      label: 'Captured At'.tr,
                      value: formatDateTime(_plotLocation!.capturedAt),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Land Split',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('new_farmer_total_land_field'),
                    controller: _totalLandController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(labelText: 'Total Land (acres)'),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        _validatePositiveLand(value, 'Total land') ??
                        _validateSplitTotal(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_nursery_land_field'),
                    controller: _nurseryLandController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                        labelText: 'Nursery Land (acres)'),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        _validatePositiveLand(value, 'Nursery land') ??
                        _validateSplitTotal(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_main_land_field'),
                    controller: _mainLandController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(labelText: 'Main Land (acres)'),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        _validatePositiveLand(value, 'Main land') ??
                        _validateSplitTotal(),
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
      title: 'Farmer Profile'.tr,
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
                            success
                                ? 'Dialer opened.'
                                : 'Unable to open dialer.',
                          );
                        }
                      },
                      icon: const Icon(Icons.call_outlined),
                      label: Text('Call'.tr),
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
                            success
                                ? 'Messaging app opened.'
                                : 'Unable to open messaging app.',
                          );
                        }
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: Text('Message'.tr),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final success =
                            await appState.shareFarmerSummary(farmer.id);
                        if (context.mounted) {
                          showMockSnackBar(
                            context,
                            success
                                ? 'Summary shared.'
                                : 'Unable to share summary.',
                          );
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: Text('Share'.tr),
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
                    label: 'Farmer Profile'.tr,
                    selected: !isCultivationTab,
                    onTap: () =>
                        context.go('/engage/farmer/$farmerId?tab=profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DirectoryTabChip(
                    label: 'Cultivation'.tr,
                    selected: isCultivationTab,
                    onTap: () =>
                        context.go('/engage/farmer/$farmerId?tab=cultivation'),
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
              InfoPair(label: 'Full Name'.tr, value: farmer.name),
              const SizedBox(height: 10),
              InfoPair(label: 'Mobile Number'.tr, value: farmer.phone),
              const SizedBox(height: 10),
              InfoPair(label: 'Address'.tr, value: farmer.location),
              const SizedBox(height: 10),
              InfoPair(
                label: 'Total Land'.tr,
                value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
              ),
              const SizedBox(height: 10),
              InfoPair(label: 'Land Details'.tr, value: farmer.landDetails),
              const SizedBox(height: 12),
              FarmerPlotLocationSection(farmer: farmer),
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
              InfoPair(label: 'Status'.tr, value: settlement.status.label),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Support Value'.tr,
                value: currency(settlement.supportValue),
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Procurement Value'.tr,
                value: currency(settlement.procurementValue),
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Net Settlement'.tr,
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
                  child: Text('Complete Settlement'.tr),
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
                Text('No procurement records yet.'.tr)
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
                label: 'Nursery Land'.tr,
                value: '${farmer.nurseryLandAcres.toStringAsFixed(1)} acres',
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Main Crop Land'.tr,
                value: '${farmer.mainLandAcres.toStringAsFixed(1)} acres',
              ),
              const SizedBox(height: 8),
              InfoPair(label: 'Crop'.tr, value: farmer.crop),
              const SizedBox(height: 8),
              InfoPair(label: 'Season'.tr, value: farmer.season),
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
                  onPressed: () =>
                      context.go('/crop-plan?farmerId=${farmer.id}'),
                  child: Text('Open full crop plan'.tr),
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
            InfoPair(label: 'Phone'.tr, value: farmer.phone),
            const SizedBox(height: 8),
            InfoPair(label: 'Location'.tr, value: farmer.location),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Land Area'.tr,
              value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: appState.farmerTrackerSupportLabel(
                      farmer.id, SupportType.cash),
                  background: AppColors.brandBlueLight,
                  foreground: AppColors.brandBlue,
                ),
                StatusPill(
                  label: appState.farmerTrackerSupportLabel(
                      farmer.id, SupportType.kind),
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
                        color: isActive
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
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
            InfoPair(label: 'Value'.tr, value: value),
            const SizedBox(height: 8),
            InfoPair(label: 'Context'.tr, value: record.cropContext),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Reconciliation'.tr,
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
              label: 'Harvest Date'.tr,
              value: record.selectedHarvestDate == null
                  ? '-'
                  : formatDate(record.selectedHarvestDate!),
            ),
            const SizedBox(height: 8),
            InfoPair(
              label: 'Final Quantity'.tr,
              value:
                  '${(record.finalWeighingQtyKg ?? 0).toStringAsFixed(0)} kg',
            ),
            const SizedBox(height: 8),
            InfoPair(label: 'Total'.tr, value: currency(record.totalAmount)),
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
          onPressed: () =>
              context.go('/support/flow/cash?farmerId=${farmer.id}'),
          child: Text('Proceed To Booking'.tr),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () =>
              context.go('/support/flow/cash?farmerId=${farmer.id}'),
          child: Text('Start Cash Advance'.tr),
        ),
      );
    } else {
      buttons.add(
        FilledButton(
          style: filledButtonStyle(),
          onPressed: () =>
              context.go('/support/flow/kind?farmerId=${farmer.id}'),
          child: Text('Give Kind Support'.tr),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () => context.go('/crop-plan?farmerId=${farmer.id}'),
          child: Text('Open Crop Plan'.tr),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: () =>
              context.go('/harvest/procurement?farmerId=${farmer.id}'),
          child: Text('Start Procurement'.tr),
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
                success
                    ? 'Settlement completed.'
                    : 'Settlement is not ready yet.',
              );
            },
            child: Text('Complete Settlement'.tr),
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
