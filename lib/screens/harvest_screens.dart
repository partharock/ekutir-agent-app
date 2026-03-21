import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../models/farmer.dart';
import '../models/support.dart';
import '../models/procurement.dart';
import '../utils/formatters.dart';

class HarvestHubScreen extends StatefulWidget {
  const HarvestHubScreen({super.key});

  @override
  State<HarvestHubScreen> createState() => _HarvestHubScreenState();
}

class _HarvestHubScreenState extends State<HarvestHubScreen> {
  String _query = '';
  String? _selectedFarmerId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.searchFarmers(_query);

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
              child: SectionCard(
                highlighted: farmer.id == _selectedFarmerId,
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedFarmerId = farmer.id;
                  }),
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
                      InfoPair(label: 'Phone', value: farmer.phone),
                      const SizedBox(height: 8),
                      InfoPair(label: 'Location', value: farmer.location),
                      const SizedBox(height: 8),
                      InfoPair(
                        label: 'Land Area',
                        value: '${farmer.totalLandAcres.toStringAsFixed(0)} acres',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          HistoryChip(
                            label: farmer.supportHistory.any(
                              (item) => item.type == SupportType.kind,
                            )
                                ? 'Kind: Acknowledged'
                                : 'Kind: Pending',
                          ),
                          HistoryChip(
                            label: farmer.supportHistory.any(
                              (item) => item.type == SupportType.cash,
                            )
                                ? 'Cash: Acknowledged'
                                : 'Cash: Pending',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('start_procurement_button'),
            style: filledButtonStyle(),
            onPressed: _selectedFarmerId == null
                ? null
                : () {
                    appState.startProcurement(_selectedFarmerId!);
                    context.push('/harvest/procurement');
                  },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Start Procurement'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProcurementFlowScreen extends StatefulWidget {
  const ProcurementFlowScreen({super.key});

  @override
  State<ProcurementFlowScreen> createState() => _ProcurementFlowScreenState();
}

class _ProcurementFlowScreenState extends State<ProcurementFlowScreen> {
  final _harvestQtyController = TextEditingController();
  final _packagingNotesController = TextEditingController();
  final _weighingQtyController = TextEditingController();
  final _weighingNotesController = TextEditingController();
  final _receiptMessageController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _transportNotesController = TextEditingController();
  final _carrierController = TextEditingController();
  String _packagingStatus = 'Completed';

  static const _carrierOptions = ['TRK-5582', 'TRK-4471', 'TRK-6108'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncControllers());
  }

  void _syncControllers() {
    final draft = context.read<AppState>().procurementDraft;
    if (draft == null) {
      return;
    }
    _harvestQtyController.text = draft.quantityHarvestedKg.toStringAsFixed(0);
    _packagingNotesController.text = draft.packagingNotes;
    _weighingQtyController.text = draft.finalWeighingQtyKg.toStringAsFixed(0);
    _weighingNotesController.text = draft.weighingNotes;
    _receiptMessageController.text = draft.receiptMessage;
    _driverNameController.text = draft.driverName;
    _driverPhoneController.text = draft.driverPhone;
    _transportNotesController.text = draft.transportNotes;
    _carrierController.text = draft.carrierNumber;
    _packagingStatus = draft.packagingStatus;
  }

  @override
  void dispose() {
    _harvestQtyController.dispose();
    _packagingNotesController.dispose();
    _weighingQtyController.dispose();
    _weighingNotesController.dispose();
    _receiptMessageController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _transportNotesController.dispose();
    _carrierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final draft = appState.procurementDraft;
    if (draft == null) {
      return const PageScaffold(
        title: 'Procurement',
        showBack: true,
        child: EmptyStateCard(
          message: 'Select a farmer from Harvest to start procurement.'
        ),
      );
    }

    final farmer = appState.farmerById(draft.farmerId);
    final step = ProcurementStep.values[draft.stepIndex];
    final readHarvestQty =
        double.tryParse(_harvestQtyController.text) ?? draft.quantityHarvestedKg;
    final readWeighQty =
        double.tryParse(_weighingQtyController.text) ?? draft.finalWeighingQtyKg;

    return PageScaffold(
      title: 'Procurement',
      showBack: true,
      onBack: () {
        if (draft.stepIndex == 0) {
          context.pop();
          return;
        }
        appState.updateProcurementDraft(
          draft.copyWith(stepIndex: draft.stepIndex - 1),
        );
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('procurement_primary_button'),
            style: filledButtonStyle(),
            onPressed: () {
              final updatedDraft = _buildUpdatedDraft(draft);
              if (updatedDraft == null) {
                showMockSnackBar(
                  context,
                  'Please complete the current step before continuing.',
                );
                return;
              }
              if (draft.stepIndex == ProcurementStep.values.length - 1) {
                appState.updateProcurementDraft(updatedDraft);
                final success = appState.submitProcurement();
                if (success) {
                  context.go('/harvest/success');
                }
                return;
              }
              appState.updateProcurementDraft(
                updatedDraft.copyWith(stepIndex: draft.stepIndex + 1),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                draft.stepIndex == ProcurementStep.values.length - 1
                    ? 'Submit Procurement'
                    : 'Save and Continue',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              final updatedDraft = _buildUpdatedDraft(draft);
              if (updatedDraft != null) {
                appState.updateProcurementDraft(updatedDraft);
              }
              appState.saveProcurementDraft();
              showMockSnackBar(
                context,
                'Procurement draft saved for this session.',
              );
            },
            child: const Text('Save as Draft'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProcurementStepper(currentStep: draft.stepIndex),
          const SizedBox(height: 18),
          if (step == ProcurementStep.harvesting) ...[
            Text(
              'Farmer Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FarmerDetailSummary(farmer: farmer),
            const SizedBox(height: 18),
            Text(
              'Procurement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harvesting Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: TextEditingController(text: farmer.crop),
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Crop'),
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    label: 'Harvesting Date',
                    initialDate: draft.harvestingDate,
                    onDateSelected: (date) => appState.updateProcurementDraft(
                      draft.copyWith(harvestingDate: date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TimePickerField(
                    label: 'Time of Harvesting',
                    initialTime: draft.harvestingTime,
                    onTimeSelected: (value) => appState.updateProcurementDraft(
                      draft.copyWith(harvestingTime: value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _harvestQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity Harvested *',
                      suffixText: 'kg',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (step == ProcurementStep.packaging)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packaging Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Not Started', 'In Progress', 'Completed']
                        .map(
                          (label) => ChoiceChip(
                            label: Text(label),
                            selected: _packagingStatus == label,
                            onSelected: (_) => setState(() {
                              _packagingStatus = label;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    label: 'Packaging Date',
                    initialDate: draft.packagingDate,
                    onDateSelected: (date) => appState.updateProcurementDraft(
                      draft.copyWith(packagingDate: date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _packagingNotesController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          if (step == ProcurementStep.weighing) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weighing Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  DatePickerField(
                    label: 'Weighing Date',
                    initialDate: draft.weighingDate,
                    onDateSelected: (date) => appState.updateProcurementDraft(
                      draft.copyWith(weighingDate: date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weighingQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Final Weighing Quantity *',
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weighingNotesController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
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
                  Text(
                    'Quantity Comparison',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  InfoPair(
                    label: 'Harvested Qty',
                    value: '${readHarvestQty.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Final Weighed Qty',
                    value: '${readWeighQty.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Difference',
                    value:
                        '${readWeighQty >= readHarvestQty ? '+' : ''}${(readWeighQty - readHarvestQty).toStringAsFixed(0)} kg',
                  ),
                ],
              ),
            ),
          ],
          if (step == ProcurementStep.price)
            SectionCard(
              backgroundColor: AppColors.brandBlueLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(
                    label: 'Quantity',
                    value: '${readWeighQty.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Rate per kg',
                    value: '${currency(draft.ratePerKg)} / kg',
                  ),
                  const Divider(height: 24),
                  InfoPair(
                    label: 'Total Amount',
                    value: currency(readWeighQty * draft.ratePerKg),
                  ),
                ],
              ),
            ),
          if (step == ProcurementStep.receipt) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Preview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(label: 'Date', value: formatDate(draft.transportDate)),
                  const SizedBox(height: 8),
                  const InfoPair(label: 'Receipt No', value: 'REC-10293'),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Farmer', value: farmer.name),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Crop', value: farmer.crop),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Rate per kg',
                    value: currency(draft.ratePerKg),
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Quantity',
                    value: '${readWeighQty.toStringAsFixed(0)} kg',
                  ),
                  const Divider(height: 24),
                  InfoPair(
                    label: 'Total Amount',
                    value: currency(readWeighQty * draft.ratePerKg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => showMockSnackBar(
                context,
                'Receipt generation is mocked in v1.',
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Generate Receipt'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => showMockSnackBar(
                context,
                'Receipt sharing is mocked in v1.',
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share Receipt'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _receiptMessageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
          if (step == ProcurementStep.transport)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transport Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  DatePickerField(
                    label: 'Transport Date',
                    initialDate: draft.transportDate,
                    onDateSelected: (date) => appState.updateProcurementDraft(
                      draft.copyWith(transportDate: date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _carrierOptions.contains(_carrierController.text)
                        ? _carrierController.text
                        : _carrierOptions.first,
                    items: _carrierOptions
                        .map(
                          (carrier) => DropdownMenuItem<String>(
                            value: carrier,
                            child: Text(carrier),
                          ),
                        )
                        .toList(),
                    decoration:
                        const InputDecoration(labelText: 'Carrier Number'),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _carrierController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _driverNameController,
                    decoration:
                        const InputDecoration(labelText: 'Driver Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _driverPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Driver Phone No'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _transportNotesController,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Transport Notes'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  ProcurementDraft? _buildUpdatedDraft(ProcurementDraft draft) {
    final harvestQty =
        double.tryParse(_harvestQtyController.text.trim()) ??
            draft.quantityHarvestedKg;
    final finalQty =
        double.tryParse(_weighingQtyController.text.trim()) ??
            draft.finalWeighingQtyKg;
    final step = ProcurementStep.values[draft.stepIndex];

    switch (step) {
      case ProcurementStep.harvesting:
        if (harvestQty <= 0) {
          return null;
        }
        return draft.copyWith(quantityHarvestedKg: harvestQty);
      case ProcurementStep.packaging:
        return draft.copyWith(
          packagingStatus: _packagingStatus,
          packagingNotes: _packagingNotesController.text.trim().isEmpty
              ? draft.packagingNotes
              : _packagingNotesController.text.trim(),
        );
      case ProcurementStep.weighing:
        if (finalQty <= 0) {
          return null;
        }
        return draft.copyWith(
          finalWeighingQtyKg: finalQty,
          weighingNotes: _weighingNotesController.text.trim().isEmpty
              ? draft.weighingNotes
              : _weighingNotesController.text.trim(),
        );
      case ProcurementStep.price:
        return draft;
      case ProcurementStep.receipt:
        return draft.copyWith(
          receiptMessage: _receiptMessageController.text.trim().isEmpty
              ? draft.receiptMessage
              : _receiptMessageController.text.trim(),
        );
      case ProcurementStep.transport:
        if (_driverNameController.text.trim().isEmpty ||
            _driverPhoneController.text.trim().isEmpty) {
          return null;
        }
        return draft.copyWith(
          carrierNumber: _carrierController.text.trim().isEmpty
              ? draft.carrierNumber
              : _carrierController.text.trim(),
          driverName: _driverNameController.text.trim(),
          driverPhone: _driverPhoneController.text.trim(),
          transportNotes: _transportNotesController.text.trim().isEmpty
              ? draft.transportNotes
              : _transportNotesController.text.trim(),
        );
    }
  }
}

class ProcurementSuccessScreen extends StatelessWidget {
  const ProcurementSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final receipt = context.watch<AppState>().lastProcurementReceipt;

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
          const SizedBox(height: 6),
          const StatusPill(
            label: 'Submitted',
            background: AppColors.pageBackground,
            foreground: AppColors.textSecondary,
          ),
          const SizedBox(height: 18),
          if (receipt != null)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(label: 'Farmer', value: receipt.farmerName),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Harvesting Date/Time',
                    value: formatDateTime(receipt.harvestDateTime),
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Harvested Qty',
                    value: '${receipt.harvestedQtyKg.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Final Weighed Qty',
                    value: '${receipt.finalQtyKg.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Rate',
                    value: '${currency(receipt.ratePerKg)} / kg',
                  ),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Total', value: currency(receipt.totalAmount)),
                  const SizedBox(height: 8),
                  InfoPair(label: 'Receipt', value: receipt.receiptNo),
                  const SizedBox(height: 8),
                  InfoPair(
                    label: 'Transport',
                    value: '${receipt.carrierNumber} • ${receipt.driverName}',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            style: filledButtonStyle(),
            onPressed: () {
              if (receipt == null) {
                context.go('/harvest');
                return;
              }
              context.go('/engage/farmer/${receipt.farmerId}');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text('Open Farmer Profile'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/harvest'),
            child: const Text('Start New Procurement'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(ProcurementStep.values.length, (index) {
        final step = ProcurementStep.values[index];
        final isDone = index < currentStep;
        final isCurrent = index == currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= currentStep
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isCurrent
                          ? AppColors.brandGreen
                          : Colors.white,
                      border: Border.all(
                        color: isDone || isCurrent
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                  ),
                  if (index < ProcurementStep.values.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentStep
                            ? AppColors.brandGreen
                            : AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.label,
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
