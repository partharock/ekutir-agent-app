import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/translation_service.dart';
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
                  onTap: () {},
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
