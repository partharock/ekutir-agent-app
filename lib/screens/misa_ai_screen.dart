import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../theme/app_colors.dart';

class MisaAiPlaceholderScreen extends StatelessWidget {
  const MisaAiPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'MISA AI',
      child: Center(
        child: SectionCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreenLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.brandGreenDark,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'MISA AI is coming soon',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This placeholder keeps the planned navigation structure intact until the final assistant experience is designed.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => showMockSnackBar(
                    context,
                    'Assistant capability is intentionally mocked in v1.',
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View mock state'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
