import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/translation_service.dart';

class AgentProfileDrawer extends StatelessWidget {
  const AgentProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.brandBlueLight,
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appState.agentName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.brandBlue,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lead Extension Agent'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.brandBlue,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ProfileDetailItem(
                    icon: Icons.badge_outlined,
                    title: 'Agent ID'.tr,
                    value: 'AGN-89234',
                  ),
                  _ProfileDetailItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number'.tr,
                    value: '+91 98765 43210',
                  ),
                  _ProfileDetailItem(
                    icon: Icons.email_outlined,
                    title: 'Email Address'.tr,
                    value: '${appState.agentName.toLowerCase().split(' ').first}@ekutir.com',
                  ),
                  _ProfileDetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Base Location'.tr,
                    value: 'Bhubaneswar, Odisha',
                  ),
                  _ProfileDetailItem(
                    icon: Icons.agriculture_outlined,
                    title: 'Primary Crop'.tr,
                    value: appState.agentCrop,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                    title: Text(
                      'Log Out'.tr,
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      // Handled by router in real app
                      Navigator.of(context).pop();
                    },
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

class _ProfileDetailItem extends StatelessWidget {
  const _ProfileDetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
