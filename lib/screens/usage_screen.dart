import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/groq_model.dart';
import '../services/rate_limiter.dart';

/// Full usage breakdown screen — RPM, RPD, TPM, TPD per model.
class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final limiter = context.watch<RateLimiter>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'API Usage',
          style: TextStyle(
            color: Color(0xFFE6EDF3),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE6EDF3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              limiter.resetDaily();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Daily counters reset'),
                  backgroundColor: const Color(0xFF161B22),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: GroqModel.values.map((model) {
          final snap = limiter.usage(model);
          return _ModelUsageCard(model: model, snap: snap);
        }).toList(),
      ),
    );
  }
}

class _ModelUsageCard extends StatelessWidget {
  const _ModelUsageCard({required this.model, required this.snap});

  final GroqModel model;
  final dynamic snap; // UsageSnapshot

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF30363D),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF39D353).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  model.label,
                  style: const TextStyle(
                    color: Color(0xFF39D353),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                model.modelId.split('/').last,
                style: TextStyle(
                  color: const Color(0xFF8B949E),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Usage bars
          _UsageRow(
            label: 'Requests / min',
            current: snap.requestsThisMinute,
            limit: model.safeRpm,
          ),
          const SizedBox(height: 10),
          _UsageRow(
            label: 'Requests / day',
            current: snap.requestsToday,
            limit: model.safeRpd,
          ),
          const SizedBox(height: 10),
          _UsageRow(
            label: 'Tokens / min',
            current: snap.tokensThisMinute,
            limit: model.safeTpm,
          ),
          const SizedBox(height: 10),
          _UsageRow(
            label: 'Tokens / day',
            current: snap.tokensToday,
            limit: model.safeTpd,
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.current,
    required this.limit,
  });

  final String label;
  final int current;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final ratio = limit == 0 ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final color = ratio >= 0.9
        ? const Color(0xFFEF4444)
        : ratio >= 0.8
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: const Color(0xFF8B949E),
                    fontSize: 12)),
            Text(
              '$current / $limit',
              style: TextStyle(
                color: const Color(0xFF8B949E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: const Color(0xFF30363D),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
