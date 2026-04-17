import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/groq_model.dart';
import '../services/api_key_manager.dart';
import '../services/model_provider.dart';
import '../widgets/needs_api_key_prompt.dart';

/// Full-screen model switcher with detailed cards, usage stats, and live limits.
class ModelSwitcherScreen extends StatelessWidget {
  const ModelSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModelProvider>();
    final active = provider.currentModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Model',
          style: TextStyle(
              color: Color(0xFFE6EDF3), fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE6EDF3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // — Header ——————————————————————————————————————
          Text(
            'Select the model used for all AI features.',
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (context.watch<ApiKeyManager>().keys.isEmpty) ...[
            const NeedsApiKeyPrompt(),
            const SizedBox(height: 20),
          ],

          ...GroqModel.values.map((model) {
            final isActive = model == active;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModelCard(
                model: model,
                isActive: isActive,
                onTap: () => provider.setModel(model),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// — Model card ———————————————————————————————————————————

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.isActive,
    required this.onTap,
  });

  final GroqModel model;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF39D353)
                : const Color(0xFF30363D),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF39D353).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // — Header row ————————————————————————————————
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF39D353).withValues(alpha: 0.15)
                          : const Color(0xFF30363D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconFor(model),
                      size: 20,
                      color: isActive
                          ? const Color(0xFF39D353)
                          : const Color(0xFF8B949E),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + model ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.label,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFE6EDF3)
                                : const Color(0xFF8B949E),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model.modelId,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF39D353)
                                    .withValues(alpha: 0.7)
                                : const Color(0xFF8B949E),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0xFF39D353)
                          : Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF39D353)
                            : const Color(0xFF30363D),
                        width: 2,
                      ),
                    ),
                    child: isActive
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Color(0xFFE6EDF3))
                        : null,
                  ),
                ],
              ),
            ),

            // — Description ——————————————————————————————
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  model.description,
                  style: TextStyle(
                    color: const Color(0xFF8B949E),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(GroqModel model) {
    return switch (model) {
      GroqModel.fast => Icons.bolt_rounded,
      GroqModel.smart => Icons.psychology_rounded,
      GroqModel.balanced => Icons.balance_rounded,
    };
  }
}
