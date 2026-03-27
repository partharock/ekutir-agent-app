import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/farmer.dart';
import '../models/procurement.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class HarvestHubScreen extends StatefulWidget {
  const HarvestHubScreen({super.key});

  @override
  State<HarvestHubScreen> createState() => _HarvestHubScreenState();
}

class _HarvestHubScreenState extends State<HarvestHubScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.searchFarmers(_query).where(
      (farmer) => farmer.status == FarmerStatus.booked,
    );

    return PageScaffold(
      title: 'Harvesting & Procurement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            hintText: 'Search farmer name, location...',
            onChanged: (value) => setState(() {
              _query = value;
            }),
          ),
          const SizedBox(height: 18),
          Text('All Farmers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...farmers.map(
            (farmer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProcurementFarmerCard(farmer: farmer),
            ),
          ),
        ],
      ),
    );
  }
}

class ProcurementFlowScreen extends StatefulWidget {
  const ProcurementFlowScreen({
    super.key,
    this.farmerId,
    this.recordId,
    this.initialStep,
  });

  final String? farmerId;
  final String? recordId;
  final String? initialStep;

  @override
  State<ProcurementFlowScreen> createState() => _ProcurementFlowScreenState();
}

class _ProcurementFlowScreenState extends State<ProcurementFlowScreen> {
  final _harvestQtyController = TextEditingController();
  final _packagingNotesController = TextEditingController();
  final _weighingQtyController = TextEditingController();
  final _weighingNotesController = TextEditingController();
  final _rateController = TextEditingController();
  final _receiptMessageController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _transportNotesController = TextEditingController();
  final _carrierController = TextEditingController();

  String? _lastSyncKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farmerId = widget.farmerId;
      if (farmerId == null && widget.recordId == null) {
        return;
      }
      final step = widget.initialStep == null
          ? null
          : ProcurementStep.values.firstWhere(
              (item) => item.name == widget.initialStep,
              orElse: () => ProcurementStep.harvesting,
            );
      context.read<AppState>().startProcurementFlow(
            farmerId ?? context.read<AppState>().repository.procurementById(widget.recordId!)!.farmerId,
            recordId: widget.recordId,
            step: step,
          );
    });
  }

  @override
  void dispose() {
    _harvestQtyController.dispose();
    _packagingNotesController.dispose();
    _weighingQtyController.dispose();
    _weighingNotesController.dispose();
    _rateController.dispose();
    _receiptMessageController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _transportNotesController.dispose();
    _carrierController.dispose();
    super.dispose();
  }

  void _syncControllers(ProcurementRecord record, int stepIndex) {
    final syncKey = '${record.id}|${record.updatedAt.microsecondsSinceEpoch}|$stepIndex';
    if (_lastSyncKey == syncKey) {
      return;
    }
    _lastSyncKey = syncKey;
    _harvestQtyController.text =
        (record.quantityHarvestedKg ?? 0).toStringAsFixed(0);
    _packagingNotesController.text = record.packagingNotes;
    _weighingQtyController.text =
        (record.finalWeighingQtyKg ?? 0).toStringAsFixed(0);
    _weighingNotesController.text = record.weighingNotes;
    _rateController.text = record.ratePerKg.toStringAsFixed(0);
    _receiptMessageController.text = record.receiptMessage;
    _driverNameController.text = record.driverName;
    _driverPhoneController.text = record.driverPhone;
    _transportNotesController.text = record.transportNotes;
    _carrierController.text = record.carrierNumber;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final record = appState.activeProcurementRecord;
    if (record == null) {
      return const PageScaffold(
        title: 'Procurement',
        showBack: true,
        child: EmptyStateCard(
          message: 'Select a farmer from Harvest to start procurement.',
        ),
      );
    }
    _syncControllers(record, appState.procurementStepIndex);
    final farmer = appState.farmerById(record.farmerId);
    final step = ProcurementStep.values[appState.procurementStepIndex];

    return PageScaffold(
      title: 'Procurement',
      showBack: true,
      onBack: () {
        if (appState.procurementStepIndex == 0) {
          context.go('/harvest');
          return;
        }
        appState.setProcurementStep(appState.procurementStepIndex - 1);
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('procurement_primary_button'),
            style: filledButtonStyle(),
            onPressed: () => _handlePrimaryAction(context, appState, record, step),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_primaryButtonLabel(step)),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProcurementStepper(currentStep: appState.procurementStepIndex),
          const SizedBox(height: 18),
          Text('Farmer Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          FarmerDetailSummary(farmer: farmer),
          const SizedBox(height: 18),
          if (step == ProcurementStep.harvesting)
            _HarvestingStep(record: record)
          else if (step == ProcurementStep.packaging)
            _PackagingStep(record: record)
          else if (step == ProcurementStep.weighing)
            _WeighingStep(record: record)
          else if (step == ProcurementStep.price)
            _PriceStep(record: record)
          else if (step == ProcurementStep.receipt)
            _ReceiptStep(record: record)
          else
            _TransportStep(record: record),
        ],
      ),
    );
  }

  String _primaryButtonLabel(ProcurementStep step) {
    switch (step) {
      case ProcurementStep.harvesting:
        return 'Save Harvesting';
      case ProcurementStep.packaging:
        return 'Save Packaging';
      case ProcurementStep.weighing:
        return 'Save Weighing';
      case ProcurementStep.price:
        return 'Save Price';
      case ProcurementStep.receipt:
        return 'Generate Receipt';
      case ProcurementStep.transport:
        return 'Submit Procurement';
    }
  }

  void _handlePrimaryAction(
    BuildContext context,
    AppState appState,
    ProcurementRecord record,
    ProcurementStep step,
  ) {
    final updated = _buildUpdatedRecord(record, step);
    if (updated == null) {
      showMockSnackBar(
        context,
        'Please complete the current step before continuing.',
      );
      return;
    }

    appState.updateProcurementDraft(updated);
    if (step == ProcurementStep.transport) {
      final success = appState.submitProcurement();
      if (!success) {
        showMockSnackBar(context, 'Procurement is not complete yet.');
        return;
      }
      context.go('/harvest/success?recordId=${updated.id}');
      return;
    }

    appState.setProcurementStep(appState.procurementStepIndex + 1);
  }

  ProcurementRecord? _buildUpdatedRecord(
    ProcurementRecord record,
    ProcurementStep step,
  ) {
    switch (step) {
      case ProcurementStep.harvesting:
        final quantity = double.tryParse(_harvestQtyController.text.trim());
        if (record.selectedHarvestDate == null || quantity == null || quantity <= 0) {
          return null;
        }
        return record.copyWith(
          quantityHarvestedKg: quantity,
        );
      case ProcurementStep.packaging:
        if (record.packagingDate == null) {
          return null;
        }
        return record.copyWith(
          packagingDone: true,
          packagingNotes: _packagingNotesController.text.trim(),
        );
      case ProcurementStep.weighing:
        final finalQty = double.tryParse(_weighingQtyController.text.trim());
        if (record.weighingDate == null || finalQty == null || finalQty <= 0) {
          return null;
        }
        return record.copyWith(
          weighingDone: true,
          finalWeighingQtyKg: finalQty,
          weighingNotes: _weighingNotesController.text.trim(),
        );
      case ProcurementStep.price:
        final rate = double.tryParse(_rateController.text.trim());
        if (rate == null || rate <= 0 || record.finalWeighingQtyKg == null) {
          return null;
        }
        return record.copyWith(ratePerKg: rate);
      case ProcurementStep.receipt:
        return record.copyWith(
          receiptGenerated: true,
          receiptNumber: record.receiptNumber ??
              'REC-${1000 + DateTime.now().millisecond}',
          receiptMessage: _receiptMessageController.text.trim(),
        );
      case ProcurementStep.transport:
        if (record.transportDate == null ||
            _carrierController.text.trim().isEmpty ||
            _driverNameController.text.trim().isEmpty ||
            _driverPhoneController.text.trim().isEmpty ||
            !record.receiptGenerated) {
          return null;
        }
        return record.copyWith(
          transportAssigned: true,
          carrierNumber: _carrierController.text.trim(),
          driverName: _driverNameController.text.trim(),
          driverPhone: _driverPhoneController.text.trim(),
          transportNotes: _transportNotesController.text.trim(),
        );
    }
  }
}

class ProcurementSuccessScreen extends StatelessWidget {
  const ProcurementSuccessScreen({super.key, this.recordId});

  final String? recordId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final record = recordId == null
        ? appState.lastProcurementReceipt
        : appState.repository.procurementById(recordId!);

    return PageScaffold(
      title: 'Procurement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.check_circle_outline,
            size: 88,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 18),
          Text(
            'Procurement Completed',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          if (record != null)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoPair(label: 'Farmer', value: record.farmerName),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Receipt',
                    value: record.receiptNumber ?? 'Pending',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Final Quantity',
                    value: '${(record.finalWeighingQtyKg ?? 0).toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Total',
                    value: currency(record.totalAmount),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (record != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  style: filledButtonStyle(),
                  onPressed: () => context.go('/engage/farmer/${record.farmerId}?tab=profile'),
                  child: const Text('Open Farmer Profile'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final success = await appState.shareProcurementReceipt(record.id);
                    if (context.mounted) {
                      showMockSnackBar(
                        context,
                        success ? 'Receipt shared.' : 'Unable to share receipt.',
                      );
                    }
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Receipt'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final success = await appState.printProcurementReceipt(record.id);
                    if (context.mounted) {
                      showMockSnackBar(
                        context,
                        success ? 'Print dialog opened.' : 'Unable to print receipt.',
                      );
                    }
                  },
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print Receipt'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProcurementFarmerCard extends StatelessWidget {
  const _ProcurementFarmerCard({required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final procurement = appState.latestProcurement(farmer.id);
    final harvestDates = appState.harvestDateOptionsFor(farmer.id);
    final buttonLabel = procurement == null
        ? 'Start Procurement'
        : procurement.submitted
            ? 'View Receipt'
            : 'Resume Procurement';

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
          InfoPair(label: 'Phone', value: farmer.phone),
          const SizedBox(height: 8),
          InfoPair(label: 'Location', value: farmer.location),
          const SizedBox(height: 8),
          InfoPair(
            label: 'Harvest Dates',
            value: harvestDates.isEmpty
                ? 'No dates in crop plan'
                : harvestDates.map(formatDate).join(', '),
          ),
          const SizedBox(height: 8),
          InfoPair(
            label: 'Procurement Status',
            value: procurement == null
                ? 'Not started'
                : procurement.submitted
                    ? 'Submitted'
                    : '${procurement.incompleteSteps.length} steps pending',
          ),
          const SizedBox(height: 12),
          if (procurement != null && !procurement.submitted)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: procurement.incompleteSteps
                  .map(
                    (step) => StatusPill(
                      label: step.label,
                      background: AppColors.brandBlueLight,
                      foreground: AppColors.brandBlue,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          FilledButton(
            style: filledButtonStyle(),
            onPressed: () => context.go(
              '/harvest/procurement?farmerId=${farmer.id}${procurement == null ? '' : '&recordId=${procurement.id}${procurement.incompleteSteps.isEmpty ? '' : '&step=${procurement.incompleteSteps.first.name}'}'}',
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _HarvestingStep extends StatelessWidget {
  const _HarvestingStep({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Harvesting Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          DropdownButtonFormField<DateTime>(
            initialValue: record.selectedHarvestDate,
            items: record.harvestDateOptions
                .map(
                  (date) => DropdownMenuItem<DateTime>(
                    value: date,
                    child: Text(formatDate(date)),
                  ),
                )
                .toList(),
            decoration: const InputDecoration(labelText: 'Harvesting Date'),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              appState.updateProcurementDraft(record.copyWith(selectedHarvestDate: value));
            },
          ),
          const SizedBox(height: 12),
          TimePickerField(
            label: 'Time of Harvesting',
            initialTime: record.harvestingTime,
            onTimeSelected: (value) =>
                appState.updateProcurementDraft(record.copyWith(harvestingTime: value)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: (context.findAncestorStateOfType<_ProcurementFlowScreenState>()?._harvestQtyController)!,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity Harvested',
              suffixText: 'kg',
            ),
          ),
        ],
      ),
    );
  }
}

class _PackagingStep extends StatelessWidget {
  const _PackagingStep({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parent = context.findAncestorStateOfType<_ProcurementFlowScreenState>()!;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Packaging Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          DatePickerField(
            label: 'Packaging Date',
            initialDate: record.packagingDate ?? appState.today,
            onDateSelected: (date) =>
                appState.updateProcurementDraft(record.copyWith(packagingDate: date)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._packagingNotesController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Packaging Notes'),
          ),
        ],
      ),
    );
  }
}

class _WeighingStep extends StatelessWidget {
  const _WeighingStep({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parent = context.findAncestorStateOfType<_ProcurementFlowScreenState>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weighing Details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              DatePickerField(
                label: 'Weighing Date',
                initialDate: record.weighingDate ?? appState.today,
                onDateSelected: (date) =>
                    appState.updateProcurementDraft(record.copyWith(weighingDate: date)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: parent._weighingQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Final Weighing Quantity',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: parent._weighingNotesController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Weighing Notes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          backgroundColor: AppColors.brandBlueLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quantity Comparison', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              InfoPair(
                label: 'Harvested Qty',
                value: '${(record.quantityHarvestedKg ?? 0).toStringAsFixed(0)} kg',
              ),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Final Weighed Qty',
                value: '${(record.finalWeighingQtyKg ?? 0).toStringAsFixed(0)} kg',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceStep extends StatelessWidget {
  const _PriceStep({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_ProcurementFlowScreenState>()!;
    final qty = record.finalWeighingQtyKg ?? 0;
    final rate = double.tryParse(parent._rateController.text.trim()) ?? record.ratePerKg;
    return SectionCard(
      backgroundColor: AppColors.brandBlueLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          TextField(
            controller: parent._rateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rate per kg',
              prefixText: '₹',
            ),
          ),
          const SizedBox(height: 12),
          InfoPair(label: 'Quantity', value: '${qty.toStringAsFixed(0)} kg'),
          const SizedBox(height: 8),
          InfoPair(label: 'Total Amount', value: currency(qty * rate)),
        ],
      ),
    );
  }
}

class _ReceiptStep extends StatelessWidget {
  const _ReceiptStep({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parent = context.findAncestorStateOfType<_ProcurementFlowScreenState>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Receipt Preview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              InfoPair(label: 'Receipt No', value: record.receiptNumber ?? 'Pending'),
              const SizedBox(height: 8),
              InfoPair(
                label: 'Quantity',
                value: '${(record.finalWeighingQtyKg ?? 0).toStringAsFixed(0)} kg',
              ),
              const SizedBox(height: 8),
              InfoPair(label: 'Rate per kg', value: currency(record.ratePerKg)),
              const SizedBox(height: 8),
              InfoPair(label: 'Total Amount', value: currency(record.totalAmount)),
              const SizedBox(height: 12),
              TextField(
                controller: parent._receiptMessageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Farmer Message'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final updated = record.copyWith(
                  receiptGenerated: true,
                  receiptNumber: record.receiptNumber ??
                      'REC-${1000 + DateTime.now().millisecond}',
                  receiptMessage: parent._receiptMessageController.text.trim(),
                );
                appState.updateProcurementDraft(updated);
                final success = await appState.shareProcurementReceipt(updated.id);
                if (context.mounted) {
                  showMockSnackBar(
                    context,
                    success ? 'Receipt shared.' : 'Unable to share receipt.',
                  );
                }
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share Receipt'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final updated = record.copyWith(
                  receiptGenerated: true,
                  receiptNumber: record.receiptNumber ??
                      'REC-${1000 + DateTime.now().millisecond}',
                  receiptMessage: parent._receiptMessageController.text.trim(),
                );
                appState.updateProcurementDraft(updated);
                final success = await appState.printProcurementReceipt(updated.id);
                if (context.mounted) {
                  showMockSnackBar(
                    context,
                    success ? 'Print dialog opened.' : 'Unable to print receipt.',
                  );
                }
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print Receipt'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransportStep extends StatelessWidget {
  const _TransportStep({required this.record});

  final ProcurementRecord record;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parent = context.findAncestorStateOfType<_ProcurementFlowScreenState>()!;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transport Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          DatePickerField(
            label: 'Transport Date',
            initialDate: record.transportDate ?? appState.today,
            onDateSelected: (date) =>
                appState.updateProcurementDraft(record.copyWith(transportDate: date)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._carrierController,
            decoration: const InputDecoration(labelText: 'Carrier Number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._driverNameController,
            decoration: const InputDecoration(labelText: 'Driver Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._driverPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Driver Phone No'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._transportNotesController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Transport Notes'),
          ),
        ],
      ),
    );
  }
}

class ProcurementStepper extends StatelessWidget {
  const ProcurementStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(ProcurementStep.values.length, (index) {
        final step = ProcurementStep.values[index];
        final isActive = index <= currentStep;
        return StatusPill(
          label: step.label,
          background:
              isActive ? AppColors.brandGreenLight : AppColors.surfaceMuted,
          foreground:
              isActive ? AppColors.brandGreenDark : AppColors.textSecondary,
        );
      }),
    );
  }
}
