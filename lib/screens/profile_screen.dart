import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/translation_service.dart';
import '../widgets/common.dart';
import '../widgets/device_chrome.dart';

// ─── Profile Screen ───────────────────────────────────────────────────────────
// Matches Figma "My Profile" screen:
// Centered Montserrat title + 3 menu rows (User Account, Settings, Logout)

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 52), // status bar space
                // Title: Montserrat 700 24px #1C1B1F
                Text(
                  'My Profile'.tr,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 30),
                // Menu rows
                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  label: 'User Account'.tr,
                  onTap: () => context.go('/profile/account'),
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings'.tr,
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.power_settings_new_outlined,
                  label: 'Logout'.tr,
                  onTap: () {
                    appState.isAuthenticated = false;
                    context.go('/sign-in');
                  },
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SimulatedStatusBar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF1C1B1F)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Account Screen (Figma 1.2) ─────────────────────────────────────────

class UserAccountScreen extends StatefulWidget {
  const UserAccountScreen({super.key});

  @override
  State<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '9876543210');
  final _countryController = TextEditingController(text: 'India');
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _blockController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _blockController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onPincodeChanged(String value) {
    if (value.length == 6) {
      setState(() {
        _stateController.text = 'Odisha';
        _blockController.text = 'Bhubaneswar';
      });
    } else if (value.length < 6) {
      setState(() {
        _stateController.text = '';
        _blockController.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                // Back button row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, size: 24, color: Color(0xFF1C1B1F)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'User Account'.tr,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1B1F),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phone Number with +91 prefix
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixText: '+91  ',
                              prefixStyle: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1C1B1F),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Country
                          TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Pincode — auto-fills State & Block
                          TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onChanged: _onPincodeChanged,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              hintText: 'e.g., 211001',
                              helperText: 'Fills State and Block automatically.',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // State (auto-filled)
                          TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              hintText: 'Select state',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Block (auto-filled)
                          TextFormField(
                            controller: _blockController,
                            decoration: const InputDecoration(
                              labelText: 'Block',
                              hintText: 'Select block',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Village
                          TextFormField(
                            controller: _villageController,
                            decoration: const InputDecoration(
                              labelText: 'Village',
                              hintText: 'Enter village',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              hintText: 'Enter address line',
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Continue button — #4F8506 bg, Roboto 700 16px per Figma
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  showMockSnackBar(context, 'Account updated.'.tr);
                                }
                              },
                              child: Text(
                                'Continue'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SimulatedStatusBar(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Updates Screen ───────────────────────────────────────────────────────────

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top == 0 ? 82 : 30,
                16,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Updates'.tr,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: appState.homeTasks.isEmpty
                        ? Center(
                            child: Text(
                              'No urgent workflow items are pending today.'.tr,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : ListView.separated(
                            itemCount: appState.homeTasks.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final task = appState.homeTasks[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandGreenLight,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Icon(
                                    Icons.circle_notifications_outlined,
                                    color: AppColors.brandGreenDark,
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(task.subtitle),
                                onTap: () => context.go(task.route),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SimulatedStatusBar(),
            ),
          ],
        ),
      ),
    );
  }
}
