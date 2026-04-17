import 'dart:math';
import 'package:flutter/material.dart';

class PixelBanner extends StatelessWidget {
  final String text;

  const PixelBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    const double cellSize = 10.0;
    const double gap = 2.0;
    const double letterSpacing = 10.0;
    const double letterWidth = 5 * cellSize + 4 * gap;
    
    final double width = text.isEmpty ? 0 : (text.length * letterWidth) + ((text.length - 1) * letterSpacing);
    const double height = 7 * cellSize + 6 * gap;

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            size: Size(width, height),
            painter: _PixelBannerPainter(text: text),
          ),
        ),
      ),
    );
  }
}

class _PixelBannerPainter extends CustomPainter {
  final String text;
  
  _PixelBannerPainter({required this.text});

  static const List<Color> _shades = [
    Color(0xFF9BE9A8), // Lightest
    Color(0xFF40C463),
    Color(0xFF30A14E),
    Color(0xFF216E39), // Darkest
  ];

  static const Map<String, List<List<int>>> _font = {
    'M': [
      [1, 0, 0, 0, 1],
      [1, 1, 0, 1, 1],
      [1, 0, 1, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
    ],
    'O': [
      [0, 1, 1, 1, 0],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [0, 1, 1, 1, 0],
    ],
    'N': [
      [1, 0, 0, 0, 1],
      [1, 1, 0, 0, 1],
      [1, 0, 1, 0, 1],
      [1, 0, 0, 1, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
    ],
    'D': [
      [1, 1, 1, 0, 0],
      [1, 0, 0, 1, 0],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 1, 0],
      [1, 1, 1, 0, 0],
    ],
    'A': [
      [0, 1, 1, 1, 0],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 1, 1, 1, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
    ],
    'Y': [
      [1, 0, 0, 0, 1],
      [1, 0, 0, 0, 1],
      [0, 1, 0, 1, 0],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;
    
    final rand = Random(text.hashCode);
    final paint = Paint()..style = PaintingStyle.fill;
    
    const double cellSize = 10.0;
    const double gap = 2.0;
    const double letterSpacing = 10.0;
    const double letterWidth = 5 * cellSize + 4 * gap;
    
    double startX = 0;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i].toUpperCase();
      final matrix = _font[char];
      
      if (matrix != null) {
        for (int r = 0; r < 7; r++) {
          for (int c = 0; c < 5; c++) {
            if (matrix[r][c] == 1) {
              paint.color = _shades[rand.nextInt(_shades.length)];
              
              final x = startX + c * (cellSize + gap);
              final y = r * (cellSize + gap);
              
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, y, cellSize, cellSize),
                  const Radius.circular(2),
                ),
                paint,
              );
            }
          }
        }
      }
      startX += letterWidth + letterSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBannerPainter oldDelegate) {
    return oldDelegate.text != text;
  }
}
