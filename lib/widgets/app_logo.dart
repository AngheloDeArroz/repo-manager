import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.elevation = true,
    this.imageScale = 1.08,
  });

  final double size;
  final bool elevation;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
        boxShadow: elevation
            ? [
                BoxShadow(
                  color: const Color(0xFF39D353).withValues(alpha: 0.18),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Transform.scale(
        scale: imageScale,
        alignment: Alignment.center,
        child: Image.asset(
          'assets/icon/icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
