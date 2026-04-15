import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

// ─── Hub Screen ─────────────────────────────────────────────────────────────

class FarmerDataBankScreen extends StatelessWidget {
  const FarmerDataBankScreen({super.key, required this.farmerId});

  final String farmerId;

  static const _sections = [
    _DataBankSection(
      title: 'Personal Details',
      subtitle: 'Name, DOB, gender, qualification',
      icon: Icons.person_outline,
      route: 'personal-details',
    ),
    _DataBankSection(
      title: 'Address Details',
      subtitle: 'State, district, block, village, pincode',
      icon: Icons.location_on_outlined,
      route: 'address-details',
    ),
    _DataBankSection(
      title: 'Farm Details',
      subtitle: 'Equipment, cultivation cost, focus crops',
      icon: Icons.agriculture_outlined,
      route: 'farm-details',
    ),
    _DataBankSection(
      title: 'Farm Land Details',
      subtitle: 'Land area, ownership, polygon map, soil test',
      icon: Icons.map_outlined,
      route: 'farm-land-details',
    ),
    _DataBankSection(
      title: 'Technology & Communication',
      subtitle: 'Smartphone, WhatsApp usage',
      icon: Icons.smartphone_outlined,
      route: 'technology-communication',
    ),
    _DataBankSection(
      title: 'Identity Verification',
      subtitle: 'Aadhar number, agent reference',
      icon: Icons.badge_outlined,
      route: 'identity-verification',
    ),
    _DataBankSection(
      title: 'Household Income',
      subtitle: 'Agriculture, employment, other sources',
      icon: Icons.account_balance_wallet_outlined,
      route: 'household-income',
    ),
    _DataBankSection(
      title: 'Household Expenditure',
      subtitle: 'Food, health, education, travel',
      icon: Icons.receipt_long_outlined,
      route: 'household-expenditure',
    ),
    _DataBankSection(
      title: 'Institution Membership',
      subtitle: 'SHG, FPO, cooperative memberships',
      icon: Icons.groups_outlined,
      route: 'institution-membership',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmer = appState.farmerById(farmerId);

    return PageScaffold(
      title: 'Personal Data Bank'.tr,
      showBack: true,
      onBack: () => context.go('/engage/farmer/$farmerId?tab=profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmer header chip
          SectionCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.brandGreenDark,
                  ),
                ),
                const SizedBox(width: 12),
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
                        'View and manage personal information.'.tr,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Data Sections'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ..._sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DataBankSectionTile(
                section: section,
                onTap: () => context.go(
                  '/farmer-data-bank/$farmerId/${section.route}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataBankSection {
  const _DataBankSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _DataBankSectionTile extends StatelessWidget {
  const _DataBankSectionTile({
    required this.section,
    required this.onTap,
  });

  final _DataBankSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      useInnerPadding: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandGreenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  section.icon,
                  size: 20,
                  color: AppColors.brandGreenDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.subtitle.tr,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared view detail widget ───────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.rows});
  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            InfoPair(label: rows[i].label.tr, value: rows[i].value),
          ],
        ],
      ),
    );
  }
}

Widget _editButton(BuildContext context) => OutlinedButton.icon(
      onPressed: () => showMockSnackBar(
        context,
        'Edit functionality coming soon.',
      ),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text('Edit'.tr),
    );

// ─── Personal Details Screen ─────────────────────────────────────────────────

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final farmer = context.watch<AppState>().farmerById(farmerId);

    return PageScaffold(
      title: 'Personal Details'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'First Name', value: farmer.name.split(' ').first),
            (label: 'Last Name', value: farmer.name.split(' ').length > 1 ? farmer.name.split(' ').last : '-'),
            (label: 'Phone', value: farmer.phone),
            (label: 'Date of Birth', value: '-'),
            (label: 'Gender', value: '-'),
            (label: 'Qualification', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Address Details Screen ───────────────────────────────────────────────────

class AddressDetailsScreen extends StatelessWidget {
  const AddressDetailsScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final farmer = context.watch<AppState>().farmerById(farmerId);
    final coords = farmer.plotLocation?.coordinatesLabel ?? '-';

    return PageScaffold(
      title: 'Address Details'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Coordinates', value: coords),
            (label: 'Country', value: 'India'),
            (label: 'State', value: '-'),
            (label: 'District', value: '-'),
            (label: 'Block', value: '-'),
            (label: 'Pincode', value: '-'),
            (label: 'City', value: '-'),
            (label: 'Village', value: farmer.location),
            (label: 'Address Line 1', value: '-'),
            (label: 'Address Line 2', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Farm Details Screen ──────────────────────────────────────────────────────

class FarmDetailsScreen extends StatelessWidget {
  const FarmDetailsScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final farmer = context.watch<AppState>().farmerById(farmerId);

    return PageScaffold(
      title: 'Farm Details'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Equipment Owned', value: '-'),
            (label: 'Prev. Year Cultivation Cost (INR)', value: '-'),
            (label: 'Prev. Year Cultivation Income (INR)', value: '-'),
            (label: 'Focus Crop-1 (Kharif)', value: farmer.crop),
            (label: 'Focus Crop-2 (Rabi)', value: '-'),
            (label: 'Focus Crop-3 (Zaid)', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Farm Land Details Screen ─────────────────────────────────────────────────

class FarmLandDetailsScreen extends StatelessWidget {
  const FarmLandDetailsScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final farmer = context.watch<AppState>().farmerById(farmerId);
    final coords = farmer.plotLocation?.coordinatesLabel ?? '-';

    return PageScaffold(
      title: 'Farm Land Details'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Total Land Area', value: '${farmer.totalLandAcres.toStringAsFixed(1)} acres'),
            (label: 'Land Ownership Type', value: '-'),
            (label: 'Land Location (Village, Pincode, or Coordinates)', value: farmer.location),
            (label: 'Polygon Map', value: coords),
            (label: 'Government Land ID', value: '-'),
            (label: 'Initiatives to Join', value: '-'),
            (label: 'Soil Test Status', value: '-'),
            (label: 'Soil Test Report', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Technology & Communication Screen ───────────────────────────────────────

class TechnologyCommunicationScreen extends StatelessWidget {
  const TechnologyCommunicationScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final farmer = context.watch<AppState>().farmerById(farmerId);

    return PageScaffold(
      title: 'Technology & Communication'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Does the farmer have a smartphone?', value: '-'),
            (label: 'Does the farmer actively use WhatsApp?', value: '-'),
            (label: 'WhatsApp Phone Number', value: farmer.phone),
          ]),
        ],
      ),
    );
  }
}

// ─── Identity Verification Screen ────────────────────────────────────────────

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().farmerById(farmerId);

    return PageScaffold(
      title: 'Identity Verification'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Aadhar No.', value: '-'),
            (label: 'Agent', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Household Income Screen ──────────────────────────────────────────────────

class HouseholdIncomeScreen extends StatelessWidget {
  const HouseholdIncomeScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Household Income'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Income from Agriculture', value: '-'),
            (label: 'Employment Income', value: '-'),
            (label: 'Other Income Sources', value: '-'),
            (label: 'Remittance from Other Sources', value: '-'),
            (label: 'Diary', value: '-'),
            (label: 'Fishery', value: '-'),
            (label: 'Goatery', value: '-'),
            (label: 'Other', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Household Expenditure Screen ────────────────────────────────────────────

class HouseholdExpenditureScreen extends StatelessWidget {
  const HouseholdExpenditureScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Household Expenditure'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          _DetailSection(rows: [
            (label: 'Food Consumption', value: '-'),
            (label: 'Clothing', value: '-'),
            (label: 'House (Rent/Maintenance)', value: '-'),
            (label: 'Health Expenses', value: '-'),
            (label: 'Education', value: '-'),
            (label: 'Travel', value: '-'),
            (label: 'Social Activities (festivals, weddings...)', value: '-'),
          ]),
        ],
      ),
    );
  }
}

// ─── Institution Membership Screen ───────────────────────────────────────────

class InstitutionMembershipScreen extends StatelessWidget {
  const InstitutionMembershipScreen({super.key, required this.farmerId});
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Institution Membership'.tr,
      showBack: true,
      onBack: () => context.go('/farmer-data-bank/$farmerId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _editButton(context),
          ),
          const SizedBox(height: 12),
          const EmptyStateCard(
            message: 'No institution memberships recorded yet.',
          ),
        ],
      ),
    );
  }
}
