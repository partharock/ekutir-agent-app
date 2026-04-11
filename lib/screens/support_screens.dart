import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/farmer.dart';
import '../models/support.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lastTransaction = appState.lastSupportTransaction;
    return PageScaffold(
      title: 'Support'.tr,
      description: 'Choose the type of support you want to provide.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCard(
            icon: Icons.payments_outlined,
            iconBackground: AppColors.brandGreenLight,
            iconColor: AppColors.brandGreenDark,
            title: 'Cash Support'.tr,
            description:
                'Activate willing farmers through cash advance, code sharing, payment, and OTP acknowledgment.',
            onTap: () => context.go('/support/flow/cash'),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.inventory_2_outlined,
            iconBackground: AppColors.brandBlueLight,
            iconColor: AppColors.brandBlue,
            title: 'Kind Support'.tr,
            description:
                'Record backend-fed kind items, quantity, value, and OTP acknowledgment for in-kind delivery.',
            onTap: () => context.go('/support/flow/kind'),
          ),
          const SizedBox(height: 24),
          Text('Support Rules'.tr, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _BulletText(
            'A willing farmer becomes booked only after cash support reaches Acknowledged.',
          ),
          const SizedBox(height: 8),
          const _BulletText(
            'Every support event must end with farmer OTP verification.',
          ),
          const SizedBox(height: 24),
          Text(
            'Post-Disbursement Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoPair(
                  label: 'Total Cash Disbursed'.tr,
                  value: currency(appState.totalCashSupportValue),
                ),
                const SizedBox(height: 8),
                InfoPair(
                  label: 'Total Kind Value'.tr,
                  value: currency(appState.totalKindSupportValue),
                ),
                const SizedBox(height: 8),
                InfoPair(
                  label: 'OTP Pending'.tr,
                  value: '${appState.otpPendingSupport.length} records',
                ),
                if (lastTransaction != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  InfoPair(
                    label: 'Last Transaction'.tr,
                    value: '${lastTransaction.farmerName} • ${lastTransaction.statusLabel}',
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(
                        '/engage/farmer/${lastTransaction.farmerId}?tab=profile',
                      ),
                      child: Text('View farmer profile'.tr),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (appState.otpPendingSupport.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'OTP Follow-up',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...appState.otpPendingSupport.take(3).map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  useInnerPadding: false,
                  child: ListTile(
                    title: Text(record.farmerName),
                    subtitle: Text(
                      '${record.type.label} • ${record.statusLabel}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(
                      '/support/flow/${record.type.name}?farmerId=${record.farmerId}&recordId=${record.id}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SupportFlowScreen extends StatefulWidget {
  const SupportFlowScreen({
    super.key,
    required this.type,
    this.farmerId,
    this.recordId,
  });

  final SupportType type;
  final String? farmerId;
  final String? recordId;

  @override
  State<SupportFlowScreen> createState() => _SupportFlowScreenState();
}

class _SupportFlowScreenState extends State<SupportFlowScreen> {
  final _searchController = TextEditingController();
  final _landController = TextEditingController();
  final _cropContextController = TextEditingController();
  final _amountController = TextEditingController();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _valueController = TextEditingController();
  final _otpController = TextEditingController();

  String _searchQuery = '';
  String? _lastSyncKey;

  static const _kindItemOptions = [
    'Seeds',
    'Fertilizer',
    'Pesticides',
    'Saplings',
    'Irrigation Service',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().startSupportFlow(
            widget.type,
            farmerId: widget.farmerId,
            recordId: widget.recordId,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _landController.dispose();
    _cropContextController.dispose();
    _amountController.dispose();
    _itemController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _valueController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  int get _totalSteps => widget.type == SupportType.cash ? 5 : 3;

  void _syncControllers(SupportFlowDraft draft) {
    final syncKey = '${draft.recordId}|${draft.farmerId}|${draft.stepIndex}';
    if (_lastSyncKey == syncKey) {
      return;
    }
    _lastSyncKey = syncKey;
    _landController.text = draft.landDetails;
    _cropContextController.text = draft.cropContext;
    _amountController.text = draft.cashAmount.toStringAsFixed(0);
    _itemController.text = draft.itemName;
    _quantityController.text = draft.quantity.toStringAsFixed(0);
    _unitController.text = draft.unit;
    _valueController.text = draft.kindValue.toStringAsFixed(0);
    _otpController.text = draft.otpInput;
  }

  String _stepDescription(int step) {
    if (step == 0) {
      return 'Select a farmer to continue.';
    }
    if (step == 1) {
      return 'Capture support details before generating the confirmation code.';
    }
    if (widget.type == SupportType.cash) {
      switch (step) {
        case 2:
          return 'Generate and share the confirmation code, then mark as received.';
        case 3:
          return 'Mark the cash advance as paid.';
        case 4:
          return 'Verify OTP to reach Acknowledged and book the farmer.';
      }
    }
    return 'Verify OTP to complete the kind support delivery.';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final draft = appState.supportDraft;
    if (draft == null || draft.type != widget.type) {
      return const SizedBox.shrink();
    }
    _syncControllers(draft);

    final selectedFarmer =
        draft.farmerId == null ? null : appState.farmerById(draft.farmerId!);
    final activeRecord = appState.activeSupportRecord;
    final farmers = appState.searchFarmers(_searchQuery);

    return PageScaffold(
      title: widget.type.label,
      showBack: true,
      description: _stepDescription(draft.stepIndex),
      subtitle: 'STEP ${draft.stepIndex + 1} OF $_totalSteps'.tr.tr,
      onBack: () {
        if (draft.stepIndex == 0) {
          appState.cancelSupportFlow();
          context.go('/support');
          return;
        }
        appState.updateSupportDraft(draft.copyWith(stepIndex: draft.stepIndex - 1));
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('support_primary_button'),
            style: filledButtonStyle(),
            onPressed: () => _handlePrimaryAction(
              context,
              appState,
              draft,
              selectedFarmer,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_primaryButtonLabel(draft.stepIndex)),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SupportStageBar(record: activeRecord, type: widget.type),
          const SizedBox(height: 18),
          if (draft.stepIndex == 0) ...[
            SearchField(
              controller: _searchController,
              hintText: 'Search farmer name, location...'.tr,
              onChanged: (value) => setState(() {
                _searchQuery = value;
              }),
            ),
            const SizedBox(height: 18),
            Text('All Farmers'.tr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...farmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SupportFarmerCard(
                  farmer: farmer,
                  selected: farmer.id == draft.farmerId,
                  onTap: () => appState.updateSupportDraft(
                    draft.copyWith(
                      farmerId: farmer.id,
                      landDetails: farmer.landDetails,
                      cropContext: '${farmer.crop} / ${farmer.season}',
                    ),
                  ),
                ),
              ),
            ),
          ] else if (draft.stepIndex == 1 && selectedFarmer != null) ...[
            Text('Farmer Details'.tr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FarmerDetailSummary(farmer: selectedFarmer),
            const SizedBox(height: 18),
            Text(
              'Disbursement Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _landController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Land Details'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cropContextController,
                    decoration:
                        const InputDecoration(labelText: 'Crop / Season Context'),
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    label: 'Disbursement Date'.tr,
                    initialDate: draft.disbursementDate,
                    onDateSelected: (date) => appState.updateSupportDraft(
                      draft.copyWith(disbursementDate: date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.type == SupportType.cash) ...[
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cash Amount (₹)',
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue:
                          _kindItemOptions.contains(_itemController.text)
                              ? _itemController.text
                              : _kindItemOptions.first,
                      items: _kindItemOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Kind Item'),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        _itemController.text = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _unitController,
                            decoration:
                                const InputDecoration(labelText: 'Unit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price / Value (₹)',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (selectedFarmer != null && activeRecord != null) ...[
            Text('Farmer Details'.tr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FarmerDetailSummary(farmer: selectedFarmer),
            const SizedBox(height: 18),
            _SupportSummaryCard(record: activeRecord),
            const SizedBox(height: 16),
            if (draft.stepIndex == 2 && widget.type == SupportType.cash) ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmation Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    InfoPair(
                      label: 'Generated Code'.tr,
                      value: activeRecord.confirmationCode ?? '-',
                    ),
                    const SizedBox(height: 8),
                    InfoPair(label: 'Status'.tr, value: activeRecord.statusLabel),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final success = await appState.shareSupportCode();
                            if (context.mounted) {
                              showMockSnackBar(
                                context,
                                success
                                    ? 'Confirmation code shared.'
                                    : 'Unable to share confirmation code.',
                              );
                            }
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: Text('Share Code'.tr),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final success = await appState.messageFarmer(
                              selectedFarmer.id,
                              body:
                                  'Your eK Acre confirmation code is ${activeRecord.confirmationCode}.',
                            );
                            if (context.mounted) {
                              showMockSnackBar(
                                context,
                                success
                                    ? 'Message app opened.'
                                    : 'Unable to open messaging app.',
                              );
                            }
                          },
                          icon: const Icon(Icons.sms_outlined),
                          label: Text('Send via SMS'.tr),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (draft.stepIndex == 3 && widget.type == SupportType.cash)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Confirmation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use this step once the cash advance has actually been disbursed to the farmer.',
                    ),
                  ],
                ),
              ),
            if ((draft.stepIndex == 4 && widget.type == SupportType.cash) ||
                (draft.stepIndex == 2 && widget.type == SupportType.kind))
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OTP Verification',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    InfoPair(
                      label: 'Confirmation Code'.tr,
                      value: activeRecord.confirmationCode ?? '-',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter 4-digit OTP',
                      ),
                      onChanged: (value) => appState.updateSupportDraft(
                        draft.copyWith(otpInput: value),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _primaryButtonLabel(int step) {
    if (step == 0) {
      return 'Select Farmer';
    }
    if (step == 1) {
      return 'Generate Confirmation Code';
    }
    if (widget.type == SupportType.cash) {
      switch (step) {
        case 2:
          return 'Mark Received';
        case 3:
          return 'Mark Paid';
        case 4:
          return 'Verify OTP';
      }
    }
    return 'Verify OTP';
  }

  void _handlePrimaryAction(
    BuildContext context,
    AppState appState,
    SupportFlowDraft draft,
    FarmerProfile? selectedFarmer,
  ) {
    if (draft.stepIndex == 0) {
      if (draft.farmerId == null) {
        showMockSnackBar(context, 'Select a farmer to continue.');
        return;
      }
      appState.updateSupportDraft(draft.copyWith(stepIndex: 1));
      return;
    }

    if (draft.stepIndex == 1) {
      final updated = draft.copyWith(
        landDetails: _landController.text.trim(),
        cropContext: _cropContextController.text.trim(),
        cashAmount:
            double.tryParse(_amountController.text.trim()) ?? draft.cashAmount,
        itemName: _itemController.text.trim().isEmpty
            ? draft.itemName
            : _itemController.text.trim(),
        quantity:
            double.tryParse(_quantityController.text.trim()) ?? draft.quantity,
        unit: _unitController.text.trim().isEmpty
            ? draft.unit
            : _unitController.text.trim(),
        kindValue:
            double.tryParse(_valueController.text.trim()) ?? draft.kindValue,
      );
      appState.updateSupportDraft(updated);
      final success = appState.saveSupportDetails();
      if (!success) {
        showMockSnackBar(context, 'Complete the support details first.');
      }
      return;
    }

    if (widget.type == SupportType.cash && draft.stepIndex == 2) {
      final success = appState.markCashSupportReceived();
      if (!success) {
        showMockSnackBar(context, 'Unable to move to Received.');
      }
      return;
    }

    if (widget.type == SupportType.cash && draft.stepIndex == 3) {
      final success = appState.markCashSupportPaid();
      if (!success) {
        showMockSnackBar(context, 'Unable to mark cash as paid.');
      }
      return;
    }

    appState.updateSupportDraft(draft.copyWith(otpInput: _otpController.text.trim()));
    final success = appState.confirmSupportOtp();
    if (!success) {
      showMockSnackBar(context, 'OTP did not match the generated code.');
      return;
    }
    if (selectedFarmer != null) {
      context.go('/support/success?farmerId=${selectedFarmer.id}');
    } else {
      context.go('/support/success');
    }
  }
}

class SupportSuccessScreen extends StatelessWidget {
  const SupportSuccessScreen({super.key, this.farmerId});

  final String? farmerId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final transaction = appState.lastSupportTransaction;
    final targetFarmerId = farmerId ?? transaction?.farmerId;
    final title = transaction?.type == SupportType.kind
        ? 'Kind Support Completed'
        : 'Cash Disbursement Completed';

    return PageScaffold(
      title: transaction?.type.label ?? 'Support',
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.check_circle_outline,
            size: 90,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (transaction != null)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoPair(label: 'Farmer'.tr, value: transaction.farmerName),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Status'.tr, value: transaction.statusLabel),
                  const SizedBox(height: 8),
                  if (transaction.type == SupportType.cash)
                    InfoPair(
                      label: 'Cash Amount'.tr,
                      value: currency(transaction.cashAmount ?? 0),
                    )
                  else
                    InfoPair(
                      label: 'Kind Value'.tr,
                      value: currency(transaction.kindValue ?? 0),
                    ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Date'.tr,
                    value: formatDate(transaction.disbursementDate),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (targetFarmerId != null)
            FilledButton(
              style: filledButtonStyle(),
              onPressed: () => context.go('/engage/farmer/$targetFarmerId?tab=profile'),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text('View Farmer Profile'.tr),
              ),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/support'),
            child: Text('Return To Support'.tr),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• '.tr),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _SupportFarmerCard extends StatelessWidget {
  const _SupportFarmerCard({
    required this.farmer,
    required this.selected,
    required this.onTap,
  });

  final FarmerProfile farmer;
  final bool selected;
  final VoidCallback onTap;

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
          ],
        ),
      ),
    );
  }
}

class _SupportStageBar extends StatelessWidget {
  const _SupportStageBar({required this.record, required this.type});

  final SupportRecord? record;
  final SupportType type;

  @override
  Widget build(BuildContext context) {
    final labels = type == SupportType.cash
        ? CashSupportStage.values.map((item) => item.label).toList()
        : KindSupportStage.values.map((item) => item.label).toList();

    final currentLabel = record?.statusLabel;
    final currentIndex = currentLabel == null ? -1 : labels.indexOf(currentLabel);

    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = index <= currentIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StatusPill(
              label: labels[index],
              background:
                  isActive ? AppColors.brandGreenLight : AppColors.surfaceMuted,
              foreground:
                  isActive ? AppColors.brandGreenDark : AppColors.textSecondary,
            ),
          ),
        );
      }),
    );
  }
}

class _SupportSummaryCard extends StatelessWidget {
  const _SupportSummaryCard({required this.record});

  final SupportRecord record;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          InfoPair(label: 'Farmer'.tr, value: record.farmerName),
          const SizedBox(height: 8),
          InfoPair(label: 'Context'.tr, value: record.cropContext),
          const SizedBox(height: 8),
          InfoPair(
            label: record.type == SupportType.cash ? 'Amount' : 'Item',
            value: record.type == SupportType.cash
                ? currency(record.cashAmount ?? 0)
                : '${record.itemName} • ${record.quantity?.toStringAsFixed(0)} ${record.unit}',
          ),
          const SizedBox(height: 8),
          if (record.type == SupportType.kind)
            InfoPair(
              label: 'Value'.tr,
              value: currency(record.kindValue ?? 0),
            ),
          if (record.type == SupportType.kind) const SizedBox(height: 8),
          InfoPair(label: 'Status'.tr, value: record.statusLabel),
          const SizedBox(height: 8),
          InfoPair(
            label: 'Date'.tr,
            value: formatDate(record.disbursementDate),
          ),
        ],
      ),
    );
  }
}
