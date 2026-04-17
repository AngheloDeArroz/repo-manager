import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/groq_model.dart';
import '../services/model_provider.dart';

/// Horizontal chip row for switching between Groq models.
///
/// Shows label + model ID subtitle. Highlights the active selection.
class ModelSelectorChip extends StatelessWidget {
  const ModelSelectorChip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModelProvider>();
    final active = provider.currentModel;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: GroqModel.values.length,
        separatorBuilder: (_, i0) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final model = GroqModel.values[i];
          final isActive = model == active;

          return GestureDetector(
            onTap: () => provider.setModel(model),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF39D353)
                    : const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF39D353)
                      : const Color(0xFF30363D),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    model.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFFE6EDF3)
                          : const Color(0xFF8B949E),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Text(
                      model.modelId.split('/').last,
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
