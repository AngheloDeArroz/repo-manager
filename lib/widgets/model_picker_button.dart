import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/groq_model.dart';
import '../services/model_provider.dart';

class ModelPickerButton extends StatelessWidget {
  const ModelPickerButton({
    super.key,
    this.isUp = false,
  });

  final bool isUp;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModelProvider>();
    final active = provider.currentModel;

    return PopupMenuButton<GroqModel>(
      initialValue: active,
      onSelected: (model) => provider.setModel(model),
      offset: isUp ? const Offset(0, -120) : const Offset(0, 40),
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF30363D)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF30363D)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(active),
              size: 14,
              color: const Color(0xFF39D353),
            ),
            const SizedBox(width: 6),
            Text(
              active.label,
              style: TextStyle(
                color: const Color(0xFFE6EDF3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: const Color(0xFF8B949E),
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return GroqModel.values.map((model) {
          final isActive = model == active;
          return PopupMenuItem<GroqModel>(
            value: model,
            child: Row(
              children: [
                Icon(
                  _iconFor(model),
                  size: 16,
                  color: isActive ? const Color(0xFF39D353) : const Color(0xFF8B949E),
                ),
                const SizedBox(width: 10),
                Text(
                  model.label,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFE6EDF3) : const Color(0xFF8B949E),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  IconData _iconFor(GroqModel model) {
    return switch (model) {
      GroqModel.fast => Icons.bolt_rounded,
      GroqModel.smart => Icons.psychology_rounded,
      GroqModel.balanced => Icons.balance_rounded,
    };
  }
}
