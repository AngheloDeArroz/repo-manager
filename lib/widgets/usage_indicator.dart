import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/model_provider.dart';
import '../services/rate_limiter.dart';
import '../screens/usage_screen.dart';

/// Compact bar showing live RPM / TPM utilisation for the active model.
///
/// Color-coded: green → amber (≥ 80 %) → red (≥ 90 %).
/// Tap to open the full [UsageScreen].
class UsageIndicator extends StatelessWidget {
  const UsageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ModelProvider>().currentModel;
    final limiter = context.watch<RateLimiter>();
    final snap = limiter.usage(model);

    final rpmRatio = snap.rpmPercent(model.safeRpm).clamp(0.0, 1.0);
    final tpmRatio = snap.tpmPercent(model.safeTpm).clamp(0.0, 1.0);
    final maxRatio = snap
        .maxPercent(
          safeRpm: model.safeRpm,
          safeRpd: model.safeRpd,
          safeTpm: model.safeTpm,
          safeTpd: model.safeTpd,
        )
        .clamp(0.0, 1.0);

    final color = maxRatio >= 0.9
        ? const Color(0xFFEF4444)
        : maxRatio >= 0.8
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UsageScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          border: Border(
            top: BorderSide(
                color: const Color(0xFF30363D)),
          ),
        ),
        child: Row(
          children: [
            // Pulsing dot
            _StatusDot(color: color),
            const SizedBox(width: 10),

            // RPM bar
            Expanded(
                child:
                    _MiniBar(label: 'RPM', ratio: rpmRatio, color: color)),
            const SizedBox(width: 12),

            // TPM bar
            Expanded(
                child:
                    _MiniBar(label: 'TPM', ratio: tpmRatio, color: color)),

            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFF8B949E), size: 20),
          ],
        ),
      ),
    );
  }
}

// — Private helpers ——————————————————————————————————————

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _ctrl.value * 0.5),
          boxShadow: [
            BoxShadow(
              color:
                  widget.color.withValues(alpha: 0.4 * _ctrl.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label  ${(ratio * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8B949E),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 3,
            backgroundColor: const Color(0xFF30363D),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
