import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/device_chrome.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.homeTasks.take(3).toList();
    final mediaQuery = MediaQuery.of(context);
    final simulatedStatusTop = mediaQuery.padding.top == 0 ? 52.0 : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF294190), Color(0xFF4F8506)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          tooltip: 'Open assistant'.tr,
          onPressed: () => context.go('/misa-ai'),
          icon: const Icon(
            Icons.support_agent,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 88, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(agentName: appState.agentName),
                    const SizedBox(height: 28),
                    Text(
                      "Today's Priorities",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C1B1F),
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (tasks.isEmpty)
                      EmptyStateCard(
                        message:
                            'No urgent workflow items are pending today.'.tr,
                      )
                    else
                      ...tasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(task: task),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: ColoredBox(color: Colors.white)),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SimulatedStatusBar(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    simulatedStatusTop,
                    16,
                    90,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _MisaHomePanel(
                      agentName: appState.agentName,
                      topOffset: simulatedStatusTop,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.agentName});

  final String agentName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4E8),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person_outline, color: AppColors.brandGreen),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1C1919),
                    ),
              ),
              Text(
                agentName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      color: const Color(0xFF1C1919),
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: IconButton(
            tooltip: 'Updates'.tr,
            onPressed: () => context.go('/updates'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ),
      ],
    );
  }
}

class _MisaHomePanel extends StatelessWidget {
  const _MisaHomePanel({
    required this.agentName,
    required this.topOffset,
  });

  final String agentName;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight =
            (MediaQuery.sizeOf(context).height - topOffset - 160)
                .clamp(520.0, 704.0);
        return Container(
          height: panelHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFEFEFE),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: const Color(0xFFD9D9D9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi $agentName',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              color: const Color(0xFF1C1919),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'I\'m '),
                            TextSpan(
                              text: 'MISA',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.brandGreenDark,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const TextSpan(
                              text: ' - Your Farming Assistant!',
                            ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              height: 1.16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C1919),
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Ask me anything about farming techniques, crop management, or agricultural advice.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.5,
                              color: const Color(0xFF1C1919),
                            ),
                      ),
                      const Spacer(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: const [
                            _SuggestedQuestionChip(
                              label: 'Recommended question here?',
                            ),
                            SizedBox(width: 16),
                            _SuggestedQuestionChip(
                              label: 'What services can help me right now?',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFEFE),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/misa-ai'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ask anything...',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF757575),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FFF0),
                        border: Border.all(color: const Color(0xFFE6F1D9)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: IconButton(
                        tooltip: 'Send'.tr,
                        onPressed: () => context.go('/misa-ai'),
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.brandGreenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestedQuestionChip extends StatelessWidget {
  const _SuggestedQuestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.go('/misa-ai'),
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF8FFF0),
        foregroundColor: AppColors.brandGreenDark,
        side: const BorderSide(color: Color(0xFFE6F1D9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets (still needed by home and other screens)
// ─────────────────────────────────────────────────────────────────────────────

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(
                label: task.statusLabel,
                background: task.priority.color.withValues(alpha: 0.12),
                foreground: task.priority.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(task.route),
              child: Text(task.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

extension on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.danger;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.brandBlue;
    }
  }
}
