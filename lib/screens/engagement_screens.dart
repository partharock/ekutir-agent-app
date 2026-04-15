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
// MetricCard and FarmerTrackerCard moved here from home_screen.dart

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
    final trackerFarmers = appState.priorityFarmers;
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
          // ── Snapshot Metrics ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SnapChip(
                  label: 'WILLING'.tr,
                  value: '${appState.willingCount}',
                  color: AppColors.brandGreenDark,
                  bg: AppColors.brandGreenLight,
                ),
                const SizedBox(width: 8),
                _SnapChip(
                  label: 'BOOKED'.tr,
                  value: '${appState.bookedCount}',
                  color: AppColors.brandBlue,
                  bg: AppColors.brandBlueLight,
                ),
                const SizedBox(width: 8),
                _SnapChip(
                  label: 'NURSERY'.tr,
                  value: '${appState.nurseryCount}',
                  color: AppColors.heroForest,
                  bg: AppColors.heroMist,
                ),
                const SizedBox(width: 8),
                _SnapChip(
                  label: 'TRANSPLANTED'.tr,
                  value: '${appState.growthCount}',
                  color: const Color(0xFF558B2F),
                  bg: const Color(0xFFF1F8E9),
                ),
                const SizedBox(width: 8),
                _SnapChip(
                  label: 'HARVEST'.tr,
                  value: '${appState.harvestCount}',
                  color: const Color(0xFFF57F17),
                  bg: const Color(0xFFFFF8E1),
                ),
                const SizedBox(width: 8),
                _SnapChip(
                  label: 'PROCUREMENT'.tr,
                  value: '${appState.procurementCount}',
                  color: const Color(0xFF5E35B1),
                  bg: const Color(0xFFEDE7F6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Farmer Status Tracker ─────────────────────────────────────
          Text(
            'Farmer Status Tracker'.tr,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Latest stage and transactions status per farmer'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...trackerFarmers.map(
            (farmer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FarmerTrackerCard(farmer: farmer),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),

          // ── Search & Filter ───────────────────────────────────────────
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
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Add Willing Farmer'),
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
  // New fields
  final _groupNameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankUpiController = TextEditingController();

  FarmerType _farmerType = FarmerType.individual;
  bool _defaultsApplied = false;
  PlotLocation? _plotLocation;
  bool _isCapturingPlotLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied) return;
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
    _groupNameController.dispose();
    _aadharController.dispose();
    _bankHolderController.dispose();
    _bankNameController.dispose();
    _bankAccController.dispose();
    _bankIfscController.dispose();
    _bankUpiController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final bankDetails = BankDetails(
      accountHolderName: _bankHolderController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountNumber: _bankAccController.text.trim(),
      ifscCode: _bankIfscController.text.trim(),
      upiId: _bankUpiController.text.trim(),
    );

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
      farmerType: _farmerType,
      groupName: _farmerType == FarmerType.group ? _groupNameController.text.trim() : null,
      aadharNumber: _aadharController.text.trim().isEmpty ? null : _aadharController.text.trim(),
      bankDetails: bankDetails.isEmpty ? null : bankDetails,
    );

    final farmer = appState.addWillingFarmer(draft);
    if (farmer == null) {
      showMockSnackBar(context, 'Unable to save farmer details.');
      return;
    }

    showMockSnackBar(context, 'Farmer enrolled successfully.');
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
            // ── Farmer Type ─────────────────────────────────────────────
            Text('Farmer Type'.tr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<FarmerType>(
                    segments: FarmerType.values
                        .map((t) => ButtonSegment<FarmerType>(
                              value: t,
                              label: Text(t.label),
                            ))
                        .toList(),
                    selected: {_farmerType},
                    onSelectionChanged: (selection) =>
                        setState(() => _farmerType = selection.first),
                    showSelectedIcon: false,
                  ),
                  if (_farmerType == FarmerType.group) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('new_farmer_group_name_field'),
                      controller: _groupNameController,
                      decoration: const InputDecoration(labelText: 'Group Name'),
                      validator: (v) => _farmerType == FarmerType.group
                          ? _validateRequired(v, 'Group name')
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ── Basic Details ───────────────────────────────────────────
            Text('Basic Details'.tr, style: Theme.of(context).textTheme.titleLarge),
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
            const SizedBox(height: 18),
            // ── Identity Details ──────────────────────────────────────
            Text('Identity'.tr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SectionCard(
              child: TextFormField(
                key: const Key('new_farmer_aadhar_field'),
                controller: _aadharController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: const InputDecoration(
                  labelText: 'Aadhar Number',
                  helperText: '12-digit Aadhar number (optional)',
                ),
              ),
            ),
            const SizedBox(height: 18),
            // ── Bank Details ──────────────────────────────────────────
            Text('Bank Details'.tr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Required for direct benefit transfer'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('new_farmer_bank_holder_field'),
                    controller: _bankHolderController,
                    decoration: const InputDecoration(labelText: 'Account Holder Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_bank_name_field'),
                    controller: _bankNameController,
                    decoration: const InputDecoration(labelText: 'Bank Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_bank_acc_field'),
                    controller: _bankAccController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_bank_ifsc_field'),
                    controller: _bankIfscController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'IFSC Code'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_bank_upi_field'),
                    controller: _bankUpiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID',
                      helperText: 'Optional',
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
          const SizedBox(height: 8),
          // Personal Data Bank shortcut
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/farmer-data-bank/$farmerId'),
              icon: const Icon(Icons.account_circle_outlined),
              label: Text('View Personal Data Bank'.tr),
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
                'Support Coverage',
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
        // ── Solution Kit ────────────────────────────────────────────────
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cases_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Solution Kit'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Prescribed inputs & services for this season'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              InfoPair(label: 'Seed Variety'.tr, value: 'IR64 (Certified)'),
              const SizedBox(height: 8),
              InfoPair(label: 'Fertilizer'.tr, value: 'NPK 20:20:0 — 2 bags'),
              const SizedBox(height: 8),
              InfoPair(label: 'Pesticide'.tr, value: 'Chlorpyrifos 50 EC'),
              const SizedBox(height: 8),
              InfoPair(label: 'Advisory Visits'.tr, value: '3 planned (fortnightly)'),
              const SizedBox(height: 8),
              InfoPair(label: 'Crop Insurance'.tr, value: 'PMFBY — enrolled'),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Activity Timeline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View Full History'),
                  ),
                ],
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
    final nurseryActivities = activities
        .where((a) => a.type == CropActivityType.nurseryStart)
        .toList();
    final mainCropActivities = activities
        .where((a) => a.type != CropActivityType.nurseryStart)
        .toList();
    final allNursery = nurseryActivities.isNotEmpty ? nurseryActivities : activities.take(2).toList();
    final allMain = mainCropActivities.isNotEmpty ? mainCropActivities : activities.skip(2).take(4).toList();

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
                'Pre-Harvest Activity Tracker - Nursery',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (allNursery.isEmpty)
                const Text('No nursery activities recorded.')
              else
                ...allNursery.map(
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
                  child: Text('View Full History'.tr),
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
                'Pre-Harvest Activity Tracker - Main Crop',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (allMain.isEmpty)
                const Text('No main crop activities recorded.')
              else
                ...allMain.map(
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
                  child: Text('View Full Crop Plan'.tr),
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
          child: Text('Book Farmer'.tr),
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
          child: Text('Disburse Support'.tr),
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

// ─── _SnapChip ────────────────────────────────────────────────────────────────

class _SnapChip extends StatelessWidget {
  const _SnapChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── FarmerTrackerCard ────────────────────────────────────────────────────────

class FarmerTrackerCard extends StatelessWidget {
  const FarmerTrackerCard({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      farmer.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: 'Cash: ${appState.farmerTrackerSupportLabel(farmer.id, SupportType.cash)}',
                background: AppColors.brandGreenLight,
                foreground: AppColors.brandGreenDark,
              ),
              StatusPill(
                label: 'Kind: ${appState.farmerTrackerSupportLabel(farmer.id, SupportType.kind)}',
                background: AppColors.heroMist,
                foreground: AppColors.heroForest,
              ),
              StatusPill(
                label: 'Procurement: ${appState.farmerTrackerProcurementLabel(farmer.id)}',
                background: AppColors.brandBlueLight,
                foreground: AppColors.brandBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/engage/farmer/${farmer.id}?tab=profile'),
              child: Text('View Details'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
