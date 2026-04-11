import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/misa.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class MisaAiScreen extends StatefulWidget {
  const MisaAiScreen({
    super.key,
    this.initialMode,
    this.farmerId,
  });

  final String? initialMode;
  final String? farmerId;

  @override
  State<MisaAiScreen> createState() => _MisaAiScreenState();
}

class _MisaAiScreenState extends State<MisaAiScreen> {
  final _controller = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized || !mounted) {
        return;
      }
      _initialized = true;
      final appState = context.read<AppState>();
      final mode =
          widget.initialMode == 'farmer' ? MisaMode.farmer : MisaMode.general;
      appState.setMisaMode(mode);
      if (widget.farmerId != null) {
        appState.setMisaFarmer(widget.farmerId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitPrompt(BuildContext context, String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await context.read<AppState>().submitMisaPrompt(trimmed);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final farmers = appState.bookedFarmers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.brandBlueLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: AppColors.brandBlue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Hi ${appState.agentName.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'I’m MISA - your Farming Assistant!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How can I help you today?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('General'),
                            selected: appState.misaMode == MisaMode.general,
                            onSelected: appState.isMisaLoading
                                ? null
                                : (_) => appState.setMisaMode(MisaMode.general),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Farmer-specific'),
                            selected: appState.misaMode == MisaMode.farmer,
                            onSelected: appState.isMisaLoading
                                ? null
                                : (_) => appState.setMisaMode(MisaMode.farmer),
                          ),
                        ),
                      ],
                    ),
                    if (appState.misaMode == MisaMode.farmer) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: appState.misaFarmerId,
                        items: farmers
                            .map(
                              (farmer) => DropdownMenuItem<String>(
                                value: farmer.id,
                                child: Text(farmer.name),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Select Farmer',
                        ),
                        onChanged: appState.isMisaLoading
                            ? null
                            : appState.setMisaFarmer,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: appState.misaSuggestedPrompts.map((prompt) {
                        return OutlinedButton(
                          onPressed: appState.isMisaLoading
                              ? null
                              : () => _submitPrompt(context, prompt),
                          child: Text(
                            prompt,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                    if (appState.isMisaLoading) ...[
                      const SizedBox(height: 18),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        'MISA is reviewing the latest workflow context...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (appState.misaStatusMessage != null) ...[
                      const SizedBox(height: 18),
                      SectionCard(
                        backgroundColor: AppColors.heroMist,
                        child: Text(
                          appState.misaStatusMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (appState.misaMessages.isNotEmpty) ...[
                      Text(
                        'Conversation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...appState.misaMessages.map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MisaMessageBubble(message: message),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      enabled: !appState.isMisaLoading,
                      onSubmitted: (value) => _submitPrompt(context, value),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: filledButtonStyle(),
                    onPressed: appState.isMisaLoading
                        ? null
                        : () => _submitPrompt(context, _controller.text),
                    child: appState.isMisaLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send'),
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

class _MisaMessageBubble extends StatelessWidget {
  const _MisaMessageBubble({required this.message});

  final MisaMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.author == MisaMessageAuthor.assistant;

    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SectionCard(
          backgroundColor:
              isAssistant ? Colors.white : AppColors.brandBlueLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAssistant ? 'MISA' : 'You',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAssistant
                          ? AppColors.brandGreenDark
                          : AppColors.brandBlue,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message.message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (message.recommendation != null) ...[
                const SizedBox(height: 12),
                _RecommendationCard(recommendation: message.recommendation!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final MisaRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      backgroundColor: AppColors.heroMist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.brandGreenDark,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go(recommendation.actionRoute),
            child: Text(recommendation.actionLabel),
          ),
        ],
      ),
    );
  }
}
