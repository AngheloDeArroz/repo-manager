import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/groq_model.dart';
import '../services/model_provider.dart';

class ModelPickerButton extends StatelessWidget {
  const ModelPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModelProvider>();
    final active = provider.currentModel;

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: SizedBox(
        height: 38,
        width: 38,
        child: PopupMenuButton<GroqModel>(
          initialValue: active,
          onSelected: (model) => provider.setModel(model),
          offset: const Offset(0, -170), // Adjusted slightly to accommodate padding
          color: const Color(0xFF161B22),
          elevation: 12,
          splashRadius: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
          tooltip: 'Change AI Model',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF39D353).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                _iconFor(active),
                size: 18,
                color: const Color(0xFF39D353),
              ),
            ),
          ),
          itemBuilder: (context) {
            return GroqModel.values.map((model) {
              final isActive = model == active;
              return PopupMenuItem<GroqModel>(
                value: model,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Padding away from popup edges
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF39D353).withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12), // Squircle
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconFor(model),
                        size: 16,
                        color: isActive ? const Color(0xFF39D353) : const Color(0xFFE6EDF3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          model.label,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF39D353) : const Color(0xFFE6EDF3),
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
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

