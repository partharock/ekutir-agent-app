import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../models/farmer.dart';
import '../models/support.dart';
import '../utils/formatters.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Support',
      description: 'Choose the type of support you want to provide.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionCard(
            icon: Icons.payments_outlined,
            iconBackground: AppColors.brandGreenLight,
            iconColor: AppColors.brandGreenDark,
            title: 'Cash Support',
            description:
                'Disburse cash advances to farmers based on partnership terms and track OTP-based acknowledgments.',
            onTap: () {
              context.read<AppState>().startSupportFlow(SupportType.cash);
              context.push('/support/flow/cash');
            },
          ),
          const SizedBox(height: 14),
          ActionCard(
            icon: Icons.inventory_2_outlined,
            iconBackground: AppColors.brandBlueLight,
            iconColor: AppColors.brandBlue,
            title: 'Kind Support',
            description:
                'Deliver in-kind support items like seeds, fertilizers, and services, then confirm with OTP verification.',
            onTap: () {
              context.read<AppState>().startSupportFlow(SupportType.kind);
              context.push('/support/flow/kind');
            },
          ),
          const SizedBox(height: 24),
          Text('About Support', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const BulletText(
            'All disbursements require farmer acknowledgment via OTP.',
          ),
          const SizedBox(height: 8),
          const BulletText(
            'Support amounts and items are based on partnership agreements.',
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
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

class BulletText extends StatelessWidget {
  const BulletText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• '),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class SupportFlowScreen extends StatefulWidget {
  const SupportFlowScreen({super.key, required this.type});

  final SupportType type;

  @override
  State<SupportFlowScreen> createState() => _SupportFlowScreenState();
}

class _SupportFlowScreenState extends State<SupportFlowScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _itemController = TextEditingController();
  String _searchQuery = '';

  static const _kindItemOptions = ['Seeds', 'Fertilizer', 'Pesticides'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final draft = appState.supportDraft;
      if (draft == null || draft.type != widget.type) {
        appState.startSupportFlow(widget.type);
      }
      _syncControllers();
    });
  }

  void _syncControllers() {
    final draft = context.read<AppState>().supportDraft;
    if (draft == null) {
      return;
    }
    _amountController.text = draft.cashAmount.toStringAsFixed(0);
    _purposeController.text = draft.purpose;
    _itemController.text = draft.itemName;
  }

  String _descriptionForStep(int stepIndex) {
    if (stepIndex == 0) {
      return 'Select farmer from the list below';
    }
    if (stepIndex == 1) {
      return 'Check farmer information and enter disbursement details';
    }
    return 'Review disbursement summary and confirm transaction';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final draft = appState.supportDraft;
    if (draft == null || draft.type != widget.type) {
      return const SizedBox.shrink();
    }

    final selectedFarmer = draft.farmerId != null
        ? appState.farmerById(draft.farmerId!)
        : null;
    final farmers = appState.searchFarmers(_searchQuery);
    final stepIndex = draft.stepIndex;

    return PageScaffold(
      title: widget.type.label,
      showBack: true,
      description: _descriptionForStep(stepIndex),
      subtitle: 'STEP ${stepIndex + 1} OF 3',
      onBack: () {
        if (stepIndex == 0) {
          appState.cancelSupportFlow();
          context.pop();
          return;
        }
        appState.updateSupportDraft(draft.copyWith(stepIndex: stepIndex - 1));
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('support_primary_button'),
            style: filledButtonStyle(),
            onPressed: () {
              if (stepIndex == 0) {
                if (draft.farmerId == null) {
                  showMockSnackBar(context, 'Select a farmer to continue.');
                  return;
                }
                appState.updateSupportDraft(draft.copyWith(stepIndex: 1));
                _syncControllers();
                return;
              }

              if (stepIndex == 1) {
                final amount =
                    double.tryParse(_amountController.text.trim()) ??
                        draft.cashAmount;
                final updatedDraft = draft.copyWith(
                  cashAmount: amount,
                  purpose: _purposeController.text.trim().isEmpty
                      ? draft.purpose
                      : _purposeController.text.trim(),
                  itemName: _itemController.text.trim().isEmpty
                      ? draft.itemName
                      : _itemController.text.trim(),
                  stepIndex: 2,
                );
                appState.updateSupportDraft(updatedDraft);
                return;
              }

              final success = appState.confirmSupportFlow();
              if (success) {
                context.go('/support/success');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                stepIndex == 2
                    ? (widget.type == SupportType.cash
                        ? 'Confirm Transfer'
                        : 'Confirm Disbursement')
                    : stepIndex == 0
                        ? 'Start Disbursement'
                        : 'Continue',
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepIndex == 0) ...[
            SearchField(
              controller: _searchController,
              hintText: 'Search farmer name, location, stage...',
              onChanged: (value) => setState(() {
                _searchQuery = value;
              }),
            ),
            const SizedBox(height: 18),
            Text('All Farmers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...farmers.map(
              (farmer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FarmerListCard(
                  farmer: farmer,
                  selected: farmer.id == draft.farmerId,
                  onTap: () => appState.updateSupportDraft(
                    draft.copyWith(farmerId: farmer.id),
                  ),
                ),
              ),
            ),
          ] else if (stepIndex == 1 && selectedFarmer != null) ...[
            Text(
              'Farmer Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                  if (widget.type == SupportType.cash) ...[
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cash Amount (₹)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DatePickerField(
                      label: 'Date',
                      initialDate: draft.date,
                      onDateSelected: (date) => appState.updateSupportDraft(
                        draft.copyWith(date: date),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: _kindItemOptions.contains(_itemController.text)
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
                        setState(() {
                          _itemController.text = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ] else if (stepIndex == 2 && selectedFarmer != null) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  InfoPair(label: 'Farmer', value: selectedFarmer.name),
                  const SizedBox(height: 10),
                  InfoPair(label: 'Address', value: selectedFarmer.location),
                  const SizedBox(height: 10),
                  if (widget.type == SupportType.cash)
                    InfoPair(
                      label: 'Amount',
                      value: currency(
                        double.tryParse(_amountController.text) ??
                            draft.cashAmount,
                      ),
                    )
                  else
                    InfoPair(
                      label: 'Item',
                      value: _itemController.text.trim().isEmpty
                          ? draft.itemName
                          : _itemController.text.trim(),
                    ),
                  const SizedBox(height: 10),
                  InfoPair(
                    label: 'Purpose',
                    value: _purposeController.text.trim().isEmpty
                        ? draft.purpose
                        : _purposeController.text.trim(),
                  ),
                  const SizedBox(height: 10),
                  InfoPair(label: 'Date', value: formatDate(draft.date)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.type == SupportType.cash)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Transfer Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 14),
                    InfoPair(
                      label: 'Transfer Method',
                      value: 'Bank Transfer',
                    ),
                    SizedBox(height: 10),
                    InfoPair(label: 'Account Holder Name', value: 'Amit Kumar'),
                    SizedBox(height: 10),
                    InfoPair(label: 'Bank Name', value: 'Lorem Ipsum'),
                    SizedBox(height: 10),
                    InfoPair(label: 'Account Number', value: 'xxxxxxxxx879'),
                    SizedBox(height: 10),
                    InfoPair(label: 'Branch Code', value: '-'),
                    SizedBox(height: 10),
                    InfoPair(label: 'Reference No.', value: '11234567890'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class SupportSuccessScreen extends StatelessWidget {
  const SupportSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transaction = context.watch<AppState>().lastSupportTransaction;
    final title = transaction?.type == SupportType.kind
        ? 'Kind Support Completed!'
        : 'Cash Disbursement Completed!';

    return PageScaffold(
      title: transaction?.type.label ?? 'Support',
      child: Column(
        children: [
          const SizedBox(height: 80),
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
          Text(
            'You can view the updated support status later in farmer profile history.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          FilledButton(
            style: filledButtonStyle(),
            onPressed: () => context.go('/support'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text('Return To Support'),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerListCard extends StatelessWidget {
  const FarmerListCard({
    super.key,
    required this.farmer,
    this.onTap,
    this.selected = false,
  });

  final FarmerProfile farmer;
  final VoidCallback? onTap;
  final bool selected;

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
                  label: farmer.status.label,
                  background: farmer.status.backgroundColor,
                  foreground: farmer.status.foregroundColor,
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
          ],
        ),
      ),
    );
  }
}
