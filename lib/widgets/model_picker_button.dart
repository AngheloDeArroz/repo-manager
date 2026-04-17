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

    return SizedBox(
      height: 38,
      width: 38,
      child: PopupMenuButton<GroqModel>(
        initialValue: active,
        onSelected: (model) => provider.setModel(model),
        // Push the menu upward so it sits above the input field
        offset: const Offset(0, -140),
        color: const Color(0xFF161B22),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        tooltip: 'Change AI Model',
        child: Icon(
          _iconFor(active),
          size: 20,
          color: const Color(0xFF39D353),
        ),
        itemBuilder: (context) {
          return GroqModel.values.map((model) {
            final isActive = model == active;
            return PopupMenuItem<GroqModel>(
              value: model,
              height: 44,
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
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
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

