import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/groq_model.dart';
import '../services/api_key_manager.dart';
import '../services/model_provider.dart';
import '../services/rate_limiter.dart';
import '../widgets/needs_api_key_prompt.dart';

/// Full-screen model switcher with detailed cards, usage stats, and live limits.
class ModelSwitcherScreen extends StatelessWidget {
  const ModelSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModelProvider>();
    final rateLimiter = context.watch<RateLimiter>();
    final active = provider.currentModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Model',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (context.watch<ApiKeyManager>().keys.isEmpty) ...[
            const NeedsApiKeyPrompt(),
            const SizedBox(height: 20),
          ],

          // — Model cards ————————————————————————————————
          ...GroqModel.values.map((model) {
            final isActive = model == active;
            final usage = rateLimiter.usage(model);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModelCard(
                model: model,
                isActive: isActive,
                rpmUsed: usage.requestsThisMinute,
                rpdUsed: usage.requestsToday,
                tpmUsed: usage.tokensThisMinute,
                tpdUsed: usage.tokensToday,
                onTap: () => provider.setModel(model),
              ),
            );
          }),

          const SizedBox(height: 16),

          // — Info footer ————————————————————————————————
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 6),
                    Text(
                      'About limits',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Limits are set at 90% of Groq free tier ceiling to prevent 429 errors. '
                  'RPM/TPM reset every 60s. RPD/TPD reset at midnight UTC.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
    required this.rpmUsed,
    required this.rpdUsed,
    required this.tpmUsed,
    required this.tpdUsed,
    required this.onTap,
  });

  final GroqModel model;
  final bool isActive;
  final int rpmUsed;
  final int rpdUsed;
  final int tpmUsed;
  final int tpdUsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.06),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
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
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconFor(model),
                      size: 20,
                      color: isActive
                          ? const Color(0xFF7C3AED)
                          : Colors.white.withValues(alpha: 0.3),
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
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model.modelId,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.3),
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
                          ? const Color(0xFF7C3AED)
                          : Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF7C3AED)
                            : Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                    child: isActive
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // — Usage bars ———————————————————————————————
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _UsageBar(
                          label: 'RPM',
                          current: rpmUsed,
                          limit: model.safeRpm,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _UsageBar(
                          label: 'TPM',
                          current: tpmUsed,
                          limit: model.safeTpm,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _UsageBar(
                          label: 'RPD',
                          current: rpdUsed,
                          limit: model.safeRpd,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _UsageBar(
                          label: 'TPD',
                          current: tpdUsed,
                          limit: model.safeTpd,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

// — Usage bar ————————————————————————————————————————————

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.label,
    required this.current,
    required this.limit,
  });

  final String label;
  final int current;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final percent = limit == 0 ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final color = percent >= 0.9
        ? const Color(0xFFEF4444)
        : percent >= 0.8
            ? const Color(0xFFFBBF24)
            : const Color(0xFF22C55E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current / ${_compact(limit)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}
