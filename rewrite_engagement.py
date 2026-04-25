import re

with open('lib/screens/engagement_screens.dart', 'r') as f:
    text = f.read()

# We want to replace _AddWillingFarmerScreenState
start_str = "class _AddWillingFarmerScreenState extends State<AddWillingFarmerScreen> {"
end_str = "class FarmerProfileScreen extends StatelessWidget {"

if start_str in text and end_str in text:
    start_idx = text.find(start_str)
    end_idx = text.find(end_str)
    
    new_state = """class _AddWillingFarmerScreenState extends State<AddWillingFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankUpiController = TextEditingController();

  final List<LandRecord> _lands = [];
  FarmerType _farmerType = FarmerType.individual;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _groupNameController.dispose();
    _aadharController.dispose();
    _bankHolderController.dispose();
    _bankNameController.dispose();
    _bankAccController.dispose();
    _bankIfscController.dispose();
    _bankUpiController.dispose();
    super.dispose();
  }

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

  Future<void> _showAddLandSheet() async {
    final result = await showModalBottomSheet<LandRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _AddLandSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _lands.add(result);
      });
    }
  }

  void _submit(AppState appState) {
    if (!_formKey.currentState!.validate()) return;
    if (_lands.isEmpty) {
      showMockSnackBar(context, 'Please add at least one land record.');
      return;
    }

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
      lands: _lands,
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
            padding: const EdgeInsets.symmetric(vertical: 16),
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
            // Farmer Type
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
            
            // Basic Details
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
                    decoration: const InputDecoration(labelText: 'Mobile Number'),
                    validator: (value) => _validatePhone(appState, value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new_farmer_location_field'),
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) => _validateRequired(value, 'Location'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            // Lands
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lands'.tr, style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _showAddLandSheet,
                  icon: const Icon(Icons.add),
                  label: Text('Add Land'.tr),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lands.isEmpty)
              const EmptyStateCard(message: 'No lands added yet. Add a land plot to continue.')
            else
              ..._lands.asMap().entries.map((entry) {
                final idx = entry.key;
                final land = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    useInnerPadding: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Plot ${idx + 1}: ${land.crop}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _lands.removeAt(idx)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Total: ${land.totalAcres} acres • ${land.season}'),
                        if (land.plotLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.map, size: 16, color: AppColors.brandGreen),
                                const SizedBox(width: 4),
                                Text(
                                  land.plotLocation!.coordinatesLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.brandGreen),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 18),
            
            // Identity
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
            
            // Bank Details
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

class _AddLandSheet extends StatefulWidget {
  const _AddLandSheet();
  @override
  State<_AddLandSheet> createState() => _AddLandSheetState();
}

class _AddLandSheetState extends State<_AddLandSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _seasonController = TextEditingController();
  final _detailsController = TextEditingController();
  final _totalController = TextEditingController();
  final _nurseryController = TextEditingController();
  final _mainController = TextEditingController();
  
  PlotLocation? _plotLocation;
  bool _isCapturingPlotLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seasonController.text.isEmpty) {
      _seasonController.text = context.read<AppState>().currentSeason;
    }
  }

  @override
  void dispose() {
    _cropController.dispose();
    _seasonController.dispose();
    _detailsController.dispose();
    _totalController.dispose();
    _nurseryController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  double? _parse(String v) => double.tryParse(v.trim());

  String? _validateRequired(String? v, String label) =>
      v == null || v.trim().isEmpty ? '$label is required.' : null;

  String? _validatePositive(String? v, String label) {
    final p = _parse(v ?? '');
    if (p == null) return 'Enter $label in acres.';
    if (p <= 0) return '$label must be > 0.';
    return null;
  }

  String? _validateSplit() {
    final t = _parse(_totalController.text);
    final n = _parse(_nurseryController.text);
    final m = _parse(_mainController.text);
    if (t != null && n != null && m != null) {
      if ((t - n - m).abs() > 0.001) {
        return 'Nursery + Main must equal Total.';
      }
    }
    return null;
  }

  Future<void> _capturePlotLocation() async {
    setState(() => _isCapturingPlotLocation = true);
    try {
      final plotLocation = await context.read<PlotLocationService>().capturePlotLocation(
        context,
        locationHint: 'Capture Plot Bounds',
        currentLocation: _plotLocation,
      );
      if (plotLocation != null && mounted) {
        setState(() => _plotLocation = plotLocation);
      }
    } catch (_) {
      if (mounted) showMockSnackBar(context, 'Unable to open map.');
    } finally {
      if (mounted) setState(() => _isCapturingPlotLocation = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final land = LandRecord(
      id: 'lnd_${DateTime.now().millisecondsSinceEpoch}',
      crop: _cropController.text.trim(),
      season: _seasonController.text.trim(),
      details: _detailsController.text.trim(),
      totalAcres: _parse(_totalController.text)!,
      nurseryAcres: _parse(_nurseryController.text)!,
      mainAcres: _parse(_mainController.text)!,
      plotLocation: _plotLocation,
    );
    Navigator.of(context).pop(land);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Land Plot', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cropController,
              decoration: const InputDecoration(labelText: 'Crop'),
              validator: (v) => _validateRequired(v, 'Crop'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seasonController,
              decoration: const InputDecoration(labelText: 'Season'),
              validator: (v) => _validateRequired(v, 'Season'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Land Details (Optional)'),
            ),
            const SizedBox(height: 16),
            Text('Acreage Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Total'),
                    onChanged: (_) => setState((){}),
                    validator: (v) => _validatePositive(v, 'Total') ?? _validateSplit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _nurseryController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Nursery'),
                    onChanged: (_) => setState((){}),
                    validator: (v) => _validatePositive(v, 'Nursery') ?? _validateSplit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _mainController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Main'),
                    onChanged: (_) => setState((){}),
                    validator: (v) => _validatePositive(v, 'Main') ?? _validateSplit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isCapturingPlotLocation ? null : _capturePlotLocation,
              icon: _isCapturingPlotLocation 
                  ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.location_on),
              label: Text(_plotLocation == null ? 'Capture Plot Map' : 'Map Captured (${_plotLocation!.polygonPoints.length} points) - Retake'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Add to Farmer'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

"""

    with open('lib/screens/engagement_screens.dart', 'w') as f:
        f.write(text[:start_idx] + new_state + text[end_idx:])
        
print("done")
